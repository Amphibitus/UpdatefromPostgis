<?php
/**
 * QGIS Project Server PRO | Design & Sync Edition
 * Synchronisiert .qgz Projekte aus PostgreSQL public.qgis_projects
 */

// Pufferung starten, um "Corrupted ZIP" durch Leerzeichen zu vermeiden
ob_start(); 
session_start();

$script_dir = __DIR__;
$service_file = $script_dir . DIRECTORY_SEPARATOR . 'pg_service.conf';
$log_file = $script_dir . DIRECTORY_SEPARATOR . 'access_log.txt';

putenv("PGSERVICEFILE=" . $service_file);

// --- HELPER: LOGGING ---
function writeToLog($message, $log_path) {
    $timestamp = date("Y-m-d H:i:s");
    $ip = $_SERVER['REMOTE_ADDR'] ?? 'unknown';
    file_put_contents($log_path, "[$timestamp] [IP: $ip] $message" . PHP_EOL, FILE_APPEND);
}

// --- HELPER: SERVICE PARSER ---
function getServiceConfigByUser($file, $targetUser) {
    if (!file_exists($file)) return null;
    $content = file_get_contents($file);
    $lines = explode("\n", $content);
    $currentService = null;
    $config = [];
    foreach ($lines as $line) {
        $line = trim($line);
        if (empty($line) || strpos($line, '#') === 0) continue;
        if (strpos($line, '[') === 0 && strpos($line, ']') !== false) {
            $currentService = substr($line, 1, strpos($line, ']') - 1);
            $config[$currentService] = [];
            continue;
        }
        if ($currentService && strpos($line, '=') !== false) {
            list($key, $value) = explode('=', $line, 2);
            $config[$currentService][trim($key)] = trim($value);
        }
    }
    foreach ($config as $serviceName => $params) {
        if (isset($params['user']) && $params['user'] === $targetUser) {
            return ['service' => $serviceName, 'password' => $params['password'] ?? null];
        }
    }
    return null;
}

// --- LOGOUT ---
if (isset($_GET['logout'])) {
    session_destroy();
    header("Location: " . strtok($_SERVER["REQUEST_URI"], '?'));
    exit;
}

// --- AUTHENTIFIZIERUNG ---
$user_name = $_GET['user'] ?? $_POST['user'] ?? $_SESSION['user'] ?? '';
$provided_key = $_GET['pass'] ?? $_POST['api_key'] ?? $_SESSION['key'] ?? '';
$service_data = getServiceConfigByUser($service_file, $user_name);

if (!$service_data || empty($provided_key) || $provided_key !== $service_data['password']) {
    writeToLog("AUTH FAILED: $user_name", $log_file);
    if (ob_get_length()) ob_end_clean();
    ?>
    <!DOCTYPE html><html lang="de"><head><meta charset="utf-8">
    <title>QGIS Server Login</title>
    <style>
        body { font-family: 'Segoe UI', Tahoma, sans-serif; background: #f4f4f4; display: flex; justify-content: center; align-items: center; height: 100vh; margin: 0; }
        .login-card { background: white; padding: 40px; border-radius: 2px; border-top: 5px solid #589632; box-shadow: 0 10px 25px rgba(0,0,0,0.1); width: 320px; text-align: center; }
        h2 { color: #333; margin-bottom: 25px; font-weight: 300; }
        .q { color: #589632; font-weight: bold; }
        input { width: 100%; padding: 12px; margin: 8px 0; border: 1px solid #ddd; box-sizing: border-box; font-size: 14px; }
        button { width: 100%; background: #589632; color: white; border: none; padding: 12px; cursor: pointer; font-weight: bold; font-size: 15px; transition: background 0.3s; margin-top: 10px; }
        button:hover { background: #467728; }
    </style></head>
    <body><div class="login-card">
        <h2><span class="q">Q</span>GIS Project Server</h2>
        <form method="POST">
            <input type="text" name="user" placeholder="Benutzername" required>
            <input type="password" name="api_key" placeholder="Passwort" required>
            <button type="submit">ANMELDEN</button>
        </form>
    </div></body></html>
    <?php
    exit;
}

$_SESSION['user'] = $user_name;
$_SESSION['key'] = $provided_key;
$targetService = $service_data['service'];

// --- DATABASE & ACTION ---
try {
    $pdo = new PDO("pgsql:service=$targetService");
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

    // --- DOWNLOAD MODUS ---
    $project_to_download = $_GET['file'] ?? $_GET['name'] ?? null;
    if ($project_to_download) {
        $stmt = $pdo->prepare('SELECT "content" FROM public.qgis_projects WHERE name = :name');
        $stmt->execute(['name' => $project_to_download]);
        $stmt->bindColumn(1, $lob, PDO::PARAM_LOB);

        if ($stmt->fetch(PDO::FETCH_BOUND)) {
            // WICHTIG: Bytea-Stream korrekt auslesen
            $content = is_resource($lob) ? stream_get_contents($lob) : $lob;
            
            if (!empty($content)) {
                if (ob_get_length()) ob_end_clean(); // Puffer leeren
                $filename = $project_to_download . (str_ends_with(strtolower($project_to_download), '.qgz') ? '' : '.qgz');
                header('Content-Type: application/x-qgis-project');
                header('Content-Disposition: attachment; filename="' . $filename . '"');
                header('Content-Length: ' . strlen($content));
                echo $content;
                exit;
            }
        }
        writeToLog("FILE EMPTY/NOT FOUND: $project_to_download", $log_file);
        http_response_code(404);
        die("Projektdatei leer oder nicht gefunden.");
    }

    // --- UI LISTENANSICHT ---
    if (ob_get_length()) ob_end_clean();
    ?>
    <!DOCTYPE html><html lang="de"><head><meta charset="utf-8">
    <title>QGIS Project Server</title>
    <style>
        :root { --qgis-green: #589632; --qgis-dark: #202124; --qgis-sidebar: #2c2c2c; --qgis-bg: #f8f9fa; --border: #dadce0; }
        body { font-family: 'Segoe UI', Arial, sans-serif; background: var(--qgis-bg); margin: 0; display: flex; height: 100vh; color: #3c4043; }
        
        /* Sidebar */
        .sidebar { width: 280px; background: var(--qgis-sidebar); color: #fff; padding: 25px; display: flex; flex-direction: column; box-shadow: 2px 0 10px rgba(0,0,0,0.2); }
        .logo { font-size: 26px; font-weight: bold; margin-bottom: 35px; letter-spacing: -1px; }
        .logo span { color: var(--qgis-green); }
        .user-box { background: rgba(255,255,255,0.05); padding: 15px; border-radius: 4px; font-size: 13px; line-height: 1.6; border-left: 3px solid var(--qgis-green); }
        .user-box b { color: var(--qgis-green); font-size: 11px; text-transform: uppercase; display: block; }
        .logout-btn { margin-top: auto; color: #ff6b6b; text-decoration: none; font-size: 13px; font-weight: bold; padding: 10px; border: 1px solid #444; text-align: center; border-radius: 4px; transition: 0.3s; }
        .logout-btn:hover { background: #444; color: #ff4f4f; }

        /* Main Content */
        .main { flex-grow: 1; padding: 40px; overflow-y: auto; }
        h1 { font-size: 24px; font-weight: 400; margin-bottom: 30px; color: var(--qgis-dark); }
        .project-table { width: 100%; border-collapse: collapse; background: white; border-radius: 8px; overflow: hidden; box-shadow: 0 1px 3px rgba(0,0,0,0.1); }
        .project-table th { background: #f1f3f4; padding: 15px; text-align: left; font-size: 12px; text-transform: uppercase; color: #5f6368; border-bottom: 2px solid var(--border); }
        .project-table td { padding: 15px; border-bottom: 1px solid var(--border); font-size: 14px; }
        .project-table tr:hover { background: #fdfdfd; }
        
        /* Badge & Button */
        .badge { background: #e8f0fe; color: #1967d2; padding: 4px 8px; border-radius: 4px; font-size: 11px; font-weight: bold; margin-right: 10px; }
        .btn-dl { display: inline-flex; align-items: center; background: #fff; border: 1px solid var(--border); padding: 8px 16px; text-decoration: none; color: #3c4043; font-size: 13px; font-weight: 500; border-radius: 4px; transition: 0.2s; }
        .btn-dl:hover { background: var(--qgis-green); color: white; border-color: var(--qgis-green); box-shadow: 0 2px 4px rgba(0,0,0,0.2); }
        .icon { margin-right: 8px; font-style: normal; }
    </style></head>
    <body>
        <div class="sidebar">
            <div class="logo"><span>Q</span>GIS Server</div>
            <div class="user-box">
                <b>Aktiver Benutzer</b> <?php echo htmlspecialchars($user_name); ?><br>
                <b>DB Service</b> <?php echo htmlspecialchars($targetService); ?>
            </div>
            <a href="?logout=1" class="logout-btn">ABMELDEN</a>
        </div>
        <div class="main">
            <h1>Verfügbare Cloud-Projekte</h1>
            <table class="project-table">
                <thead><tr><th>Typ</th><th>Projektname</th><th style="text-align:right;">Aktion</th></tr></thead>
                <tbody>
                    <?php
                    $stmt = $pdo->query('SELECT name FROM public.qgis_projects ORDER BY name ASC');
                    while ($row = $stmt->fetch()) {
                        $n = htmlspecialchars($row['name']);
                        $dl_url = "?file=$n&user=$user_name&pass=$provided_key";
                        echo "<tr>
                                <td width='50'><span class='badge'>QGZ</span></td>
                                <td><strong>$n</strong></td>
                                <td style='text-align:right;'>
                                    <a href='$dl_url' class='btn-dl'><i class='icon'>💾</i> Download</a>
                                </td>
                              </tr>";
                    }
                    ?>
                </tbody>
            </table>
        </div>
    </body></html>
    <?php

} catch (Exception $e) {
    if (ob_get_length()) ob_end_clean();
    writeToLog("DB ERROR: " . $e->getMessage(), $log_file);
    die("Datenbankfehler: Verbindung zum PG-Service konnte nicht hergestellt werden.");
}
