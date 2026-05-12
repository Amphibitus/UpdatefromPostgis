# QField Project Update Plugin & Server Documentation

This plugin allows field operators to update their active work project (`.qgz`) directly over a secure internet connection from a centralized PostgreSQL server. Manual file transfers via USB cables are no longer required.

---

## 📖 Part 1: QField Plugin User Guide

### 🚀 First-Time Setup on the Device
1. Open your existing QField project on the mobile device (supports Windows, Android, and iOS).
2. Tap the **Plugin Icon (Gear/Download Icon)** in the upper toolbar.
3. Since no configuration exists on the first run, the gray log window will display a message indicating that no settings file was found.
4. **Fill out the input fields as follows:**
   * **Server URL:** Enter your server's domain (e.g., `xxxxxxy.de/qgis_api`). The plugin automatically prepends the `https://` protocol during the request.
   * **User / Password:** Enter the PostgreSQL credentials assigned to you on the server.
   * **Project name (database):** The filename of your currently open project is automatically entered here as a default. If the project has a different name in the database, adjust it manually.
5. Tap **"Update now"** (or "Jetzt aktualisieren").

### 💾 Automatic Storage & Encryption
* As soon as you trigger the first update, the plugin automatically generates an encrypted file named `update_settings.json` directly within the active project directory.
* The password is obfuscated using a **Base64 encoding** algorithm to prevent unauthorized reading from the device's local file system.
* For all future launches, all fields will be **completely pre-filled**. You only need to open the plugin and start the download.

### 🔄 Daily Field Update Routine
1. Open the plugin window and tap **"Update now"**.
2. Monitor the real-time status in the integrated gray log window.
3. Upon a successful transfer, a green info box will appear: **"⚠️ DOWNLOAD COMPLETE: Click 'Reload project'"**.
4. Clicking **"Reload project"** closes the active session and opens the newly downloaded project file, instantly reflecting all updated geometries and attributes from the database.

---

## 🖥️ Part 2: Web Server Setup (`get_project.php`)

The PHP script processes requests sent by the plugin, authenticates the user against a server-side configuration file, and streams the project's binary data directly from PostgreSQL.

### 1. File Structure on the Server
Deploy the files to a directory on your web server (e.g., in a subdirectory like `/qgis_api/`). Two files are strictly required:
1. `get_project.php` (The synchronization backend script)
2. `pg_service.conf` (The database service configuration file)

### 2. Configuring `pg_service.conf` on the Server
To keep passwords and connection strings hidden from the PHP codebase, the script utilizes the native PostgreSQL Service Architecture. Create the `pg_service.conf` file in the same directory as the PHP script and populate it using the following structure template:



### 3. Server Authentication Architecture
When the QField plugin requests data (`get_project.php?user=...&pass=...&file=...`), the server executes these steps:
1. It extracts the incoming username and scans the server's local `pg_service.conf` for the section matching this specific user (`user=...`).
2. It compares the incoming password parameter against the `password=` key inside that identified section block.
3. **Security Gate:** Only if there is an exact match will it establish a database connection using the section name as a service handle. If authentication fails, the request is rejected, and an HTML login mask is returned.
4. The script queries the `public.qgis_projects` table for the binary `content` column of the requested project name and streams the file payload directly to the device as a native `application/x-qgis-project` binary data stream.

---

## 🛠️ Part 3: Troubleshooting

The plugin features an advanced error handling system that analyzes root causes and prints descriptive errors directly into the gray diagnostic box:


| Log Window Error | Root Cause | Solution |
| :--- | :--- | :--- |
| `SERVER-REJECT: Falsche Zugangsdaten!...` | The entered password or username is incorrect. | Verify case-sensitivity in the plugin input fields and match them exactly against the entries in the server's `pg_service.conf`. |
| `DATENBANK-FEHLER (404): Das angegebene Projekt...` | The connection is active, but the project name does not exist in the database. | Double-check the "Project name (database)" field. It must perfectly match the string stored in the `name` column of your database table. |
| `HTTP-Fehler: 0` or `HTTP-Fehler: 500` | The server is unreachable or the PHP script encountered a runtime error. | Verify the Server URL path. Inspect the `access_log.txt` file on your web server to check whether the incoming network request is hitting the server. |

---


