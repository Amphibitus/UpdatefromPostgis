// =========================================================================
// QField Plugin: Project Update via PHP/PostgreSQL (Multi-Language)
// Description: Downloads a project as .qgz and saves configurations encrypted as JSON.
// =========================================================================

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Theme
import org.qfield
import org.qgis
import QtCore

Item {
    id: updatePlugin
    
    // PROPERTIES: Global variables of the plugin
    property var mainWindow: iface.mainWindow()
    property string fullDestinationPath: ""
    property bool isSuccess: false
    property bool isNameMismatch: false 
    property string destMode:       "project" // "project" | "plugin"

    // Global buffer for configuration data
    property string storedUrl: "https://geoplaning.de/qgis_api"
    property string storedUser: ""
    property string storedPass: ""
    property string storedProject: ""
    
    // Buffer for log messages at system startup
    property string initLogBuffer: ""

    // =========================================================================
    // 1. TRANSLATION SYSTEM (Multi-Language Dictionary)
    // =========================================================================

    property var translations: {
        "de": {
            "TITLE": "PROJEKT-UPDATE",
            "LBL_SERVER": "Server-URL:",
            "LBL_USER": "Benutzer:",
            "LBL_PASS": "Passwort:",
            "LBL_PROJECT": "Projektname (Datenbank):",
            "BTN_CANCEL": "Abbrechen",
            "BTN_UPDATE": "Jetzt aktualisieren",
            "BTN_RELOAD": "Projekt neu laden",
            "STATUS_READY": "Bereit.",
            "STATUS_INIT": "Initialisiere Download...",
            "STATUS_CONNECT": "Verbindung wird aufgebaut...",
            "STATUS_SUCCESS": "ERFOLGREICH",
            "STATUS_ERR_LOGIN": "Fehler: Login abgelehnt.",
            "STATUS_ERR_DB": "Fehler: Projekt fehlt in DB.",
            "STATUS_ERR_PASS": "Fehler: Passwort falsch.",
            "TOAST_INCOMPLETE": "Eingaben unvollständig!",
            "LOG_JSON_NOT_FOUND": "Keine update_settings.json vorhanden. Bitte Felder ausfüllen.",
            "LOG_JSON_SAVE_OK": "Vorgaben erfolgreich verschlüsselt gesichert.",
            "LOG_JSON_SAVE_ERR": "Fehler: update_settings.json konnte nicht geschrieben werden.",
            "LOG_JSON_LOAD_OK": "Vorgaben erfolgreich geladen und entschlüsselt.",
            "LOG_DEFAULT_NAME": "Standard-Projektnamen als Vorgabe gewählt.",
            "LOG_OLD_FILE": "Alte Datei gefunden. Lösche: ",
            "LOG_SAVE_OK": "Datei erfolgreich gespeichert!",
            "LOG_SAVE_ERR": "FileUtils.writeFileContent gab 'false' zurück.",
            "LOG_RELOAD_ACTIVE": "Aktuelles Projekt wird neu geladen...",
            "LOG_SAVE_NEW_MANUAL": "Neues Projekt gespeichert! Bitte manuell im QField-Menü öffnen.",
            "LOG_EMPTY_SERVER": "Server sendete leere Datei.",
            "BANNER_TITLE": "Projekt bereit",
            "BANNER_BODY": "Das Projekt wurde heruntergeladen. Bitte öffnen Sie es über die Projektauswahl.",
            "INFO_ACTION": "⚠️ DOWNLOAD FERTIG:\nKlicken Sie auf 'Projekt neu laden'.",
            "ERR_JSON_SAVE": "Fehler beim Speichern der JSON-Datei: ",
            "ERR_JSON_LOAD": "Fehler beim Laden der update_settings.json: ",
            "ERR_DISK_WRITE": "Kritischer Fehler in saveToDisk: ",
            "ERR_HTML_REJECT": "SERVER-REJECT: Falsche Zugangsdaten! Server antwortet mit HTML-Login-Maske.",
            "ERR_404": "DATENBANK-FEHLER (404): Das angegebene Projekt wurde in der Datenbank-Tabelle nicht gefunden!",
            "ERR_AUTH": "ZUGRIFFS-FEHLER: Passwort oder Benutzername ist falsch! Der Server hat den Zugriff verweigert.",
            "ERR_PRE_CHECK": "Fehler bei der Inhalts-Vorprüfung: "
        },
        "en": {
            "TITLE": "PROJECT UPDATE",
            "LBL_SERVER": "Server URL:",
            "LBL_USER": "User:",
            "LBL_PASS": "Password:",
            "LBL_PROJECT": "Project name (Database):",
            "BTN_CANCEL": "Cancel",
            "BTN_UPDATE": "Update now",
            "BTN_RELOAD": "Reload project",
            "STATUS_READY": "Ready.",
            "STATUS_INIT": "Initializing download...",
            "STATUS_CONNECT": "Connecting to server...",
            "STATUS_SUCCESS": "SUCCESS",
            "STATUS_ERR_LOGIN": "Error: Login rejected.",
            "STATUS_ERR_DB": "Error: Project missing in DB.",
            "STATUS_ERR_PASS": "Error: Invalid password.",
            "TOAST_INCOMPLETE": "Entries incomplete!",
            "LOG_JSON_NOT_FOUND": "No update_settings.json found. Please fill in the fields.",
            "LOG_JSON_SAVE_OK": "Preferences successfully encrypted and saved.",
            "LOG_JSON_SAVE_ERR": "Error: Could not write update_settings.json.",
            "LOG_JSON_LOAD_OK": "Preferences successfully loaded and decrypted.",
            "LOG_DEFAULT_NAME": "No JSON configuration found. Setting current project name as default.",
            "LOG_OLD_FILE": "Old file found. Deleting: ",
            "LOG_SAVE_OK": "File saved successfully!",
            "LOG_SAVE_ERR": "FileUtils.writeFileContent returned 'false'.",
            "LOG_RELOAD_ACTIVE": "Reloading active project...",
            "LOG_SAVE_NEW_MANUAL": "New project saved! Please open it manually from the QField project selection.",
            "LOG_EMPTY_SERVER": "Server sent an empty file.",
            "BANNER_TITLE": "Project Ready",
            "BANNER_BODY": "The project has been downloaded. Please open it via the project selection menu.",
            "INFO_ACTION": "⚠️ DOWNLOAD COMPLETE:\nClick 'Reload project'.",
            "ERR_JSON_SAVE": "Error saving JSON file: ",
            "ERR_JSON_LOAD": "Error loading update_settings.json: ",
            "ERR_DISK_WRITE": "Critical error in saveToDisk: ",
            "ERR_HTML_REJECT": "SERVER REJECT: Invalid credentials! Server replied with an HTML login page.",
            "ERR_404": "DATABASE ERROR (404): The specified project was not found in the database repository table!",
            "ERR_AUTH": "ACCESS DENIED: Password or username is incorrect! The server refused authentication.",
            "ERR_PRE_CHECK": "Error during content pre-check: "
        },
        "fr": {
            "TITLE": "MISE À JOUR DU PROJET",
            "LBL_SERVER": "URL du serveur :",
            "LBL_USER": "Utilisateur :",
            "LBL_PASS": "Mot de passe :",
            "LBL_PROJECT": "Nom du projet (Base de données) :",
            "BTN_CANCEL": "Annuler",
            "BTN_UPDATE": "Mettre à jour maintenant",
            "BTN_RELOAD": "Recharger le projet",
            "STATUS_READY": "Prêt.",
            "STATUS_INIT": "Initialisation du téléchargement...",
            "STATUS_CONNECT": "Connexion au serveur...",
            "STATUS_SUCCESS": "SUCCÈS",
            "STATUS_ERR_LOGIN": "Erreur : Connexion refusée.",
            "STATUS_ERR_DB": "Erreur : Projet introuvable dans la BDD.",
            "STATUS_ERR_PASS": "Erreur : Mot de passe incorrect.",
            "TOAST_INCOMPLETE": "Champs incomplets !",
            "LOG_JSON_NOT_FOUND": "Aucun fichier update_settings.json trouvé. Veuillez remplir les champs.",
            "LOG_JSON_SAVE_OK": "Préférences chiffrées et sauvegardées avec succès.",
            "LOG_JSON_SAVE_ERR": "Erreur : Impossible d'écrire le fichier update_settings.json.",
            "LOG_JSON_LOAD_OK": "Préférences chargées et déchiffrées avec succès.",
            "LOG_DEFAULT_NAME": "Aucune configuration JSON trouvée. Nom du projet actuel défini par défaut.",
            "LOG_OLD_FILE": "Ancien fichier trouvé. Suppression : ",
            "LOG_SAVE_OK": "Fichier enregistré avec succès !",
            "LOG_SAVE_ERR": "FileUtils.writeFileContent a renvoyé 'false'.",
            "LOG_RELOAD_ACTIVE": "Rechargement du projet actif...",
            "LOG_SAVE_NEW_MANUAL": "Nouveau projet enregistré ! Veuillez l'ouvrir manuellement depuis le menu QField.",
            "LOG_EMPTY_SERVER": "Le serveur a renvoyé un fichier vide.",
            "BANNER_TITLE": "Projet Prêt",
            "BANNER_BODY": "Le projet a été téléchargé. Veuillez l'ouvrir via le menu de sélection des projets.",
            "INFO_ACTION": "⚠️ TÉLÉCHARGEMENT RÉUSSI :\nCliquez sur 'Recharger le projet'.",
            "ERR_JSON_SAVE": "Erreur lors de l'enregistrement du fichier JSON : ",
            "ERR_JSON_LOAD": "Erreur lors du chargement de update_settings.json : ",
            "ERR_DISK_WRITE": "Erreur critique dans saveToDisk : ",
            "ERR_HTML_REJECT": "REJET DU SERVEUR : Identifiants invalides ! Le serveur a répondu avec une page de connexion HTML.",
            "ERR_404": "ERREUR BDD (404) : Le projet spécifié est introuvable dans la table de la base de données !",
            "ERR_AUTH": "ACCÈS REFUSÉ : Mot de passe ou utilisateur incorrect ! Le serveur a refusé l'authentification.",
            "ERR_PRE_CHECK": "Erreur lors du pré-contrôle du contenu : "
        }
    }

    function tr(key) {
        var dict = translations["en"]; // Fallback Default: English
        var sysLang = Qt.locale().name.substring(0, 2).toLowerCase();
        if (translations[sysLang] !== undefined) {
            dict = translations[sysLang];
        }
        var val = dict[key];
        return val !== undefined ? val : key;
    }

    // =========================================================================
    // 2. HILFSFUNKTIONEN (PFADE, LOGGING, JSON & CRYPTO)
    // =========================================================================
    
    function logToQField(message, level) {
        var qglevel = (level !== undefined) ? level : 0;
        var prefix = ["ℹ️", "⚠️", "❌", "✅"][qglevel] || "•";
        var formattedMessage = prefix + " " + message;
        
        if (typeof debugLog !== "undefined" && debugLog !== null) {
            debugLog.text += "\n" + formattedMessage;
        } else {
            initLogBuffer += "\n" + formattedMessage;
        }
        console.log("QField-Plugin-Log: " + formattedMessage);
    }

    /**
     * Ermittelt das aktuelle Projektverzeichnis (frei von file:// und Pfad-Rauschen)
     */
    function getProjectDirectory() {
        var projectPathString = qgisProject.fileName ? qgisProject.fileName.toString() : "";
        if (projectPathString.indexOf("file://") === 0) {
            projectPathString = projectPathString.substring(7);
        }
        projectPathString = decodeURIComponent(projectPathString);
        projectPathString = projectPathString.replace(/\\/g, "/");
        return projectPathString.substring(0, projectPathString.lastIndexOf('/'));
    }

    /**
     * Sichert die Zugangsdaten (inklusive Server-URL und Base64-verschlüsseltem Passwort)
     */
    function saveCredentialsToJSON() {
        var dir = getProjectDirectory();
        var jsonPath = dir + "/update_settings.json";
        
        var encryptedPassword = "";
        try {
            if (storedPass !== "") {
                encryptedPassword = Qt.btoa(storedPass); 
            }
        } catch(e) {
            encryptedPassword = storedPass;
        }
        
        var settingsData = {
            "url": storedUrl,
            "user": storedUser,
            "password": encryptedPassword,
            "project": storedProject
        };
        
        try {
            var jsonString = JSON.stringify(settingsData, null, 4);
            var success = FileUtils.writeFileContent(jsonPath, jsonString);
            
            if (success) {
                logToQField(tr("LOG_JSON_SAVE_OK"), 3);
            } else {
                logToQField(tr("LOG_JSON_SAVE_ERR"), 2);
            }
        } catch (e) {
            logToQField(tr("ERR_JSON_SAVE") + e, 2);
        }
    }

    /**
     * Versucht die Vorgaben aus der update_settings.json zu laden und zu entschlüsseln.
     */
    function loadCredentialsFromJSON() {
        var dir = getProjectDirectory();
        var jsonPath = dir + "/update_settings.json";
        
        if (!FileUtils.fileExists(jsonPath)) {
            logToQField(tr("LOG_JSON_NOT_FOUND"), 0);
            return false;
        }
        
        try {
            var rawData = FileUtils.readFileContent(jsonPath);
            var content = "" + rawData;
            
            if (!content || content.trim() === "") return false;
            
            var settings = JSON.parse(content);
            
            storedUrl = settings.url || "geoplaning.de";
            storedUser = settings.user || "";
            storedProject = settings.project || "";
            
            var decryptedPassword = "";
            if (settings.password) {
                try {
                    decryptedPassword = Qt.atob(settings.password);
                } catch(e) {
                    decryptedPassword = settings.password;
                }
            }
            storedPass = decryptedPassword;
            
            logToQField(tr("LOG_JSON_LOAD_OK"), 3);
            return true;
            
        } catch (e) {
            logToQField(tr("ERR_JSON_LOAD") + e, 1);
        }
        return false;
    }

    /**
     * Aktualisiert die Textfelder in der UI-Oberfläche direkt aus dem Speicher.
     */
    function updateUIFields() {
        if (typeof urlInput !== "undefined" && urlInput !== null) {
            urlInput.text = storedUrl;
            dbUserInput.text = storedUser;
            dbPassInput.text = storedPass;
            filenameInput.text = storedProject;
        }
    }
   
    /**
     * Speichert die heruntergeladene Projekt-Binärdatei (.qgz)
     */
    function saveToDisk(targetPath, data) {
        try {
            var fileExists = FileUtils.fileExists(targetPath);
            if (fileExists) logToQField(tr("LOG_OLD_FILE") + targetPath, 0);
            
            var success = FileUtils.writeFileContent(targetPath, data);
            if (success) {
                logToQField(tr("LOG_SAVE_OK"), 3);
                return true;
            } else {
                logToQField(tr("LOG_SAVE_ERR"), 2);
                return false;
            }
        } catch (e) {
            logToQField(tr("ERR_DISK_WRITE") + e, 2);
            return false;
        }
    }

    // =========================================================================
    // 3. HAUPTLOGIK (DOWNLOAD & PROJEKT-RELOAD)
    // =========================================================================

    function triggerReload() {
        downloadDialog.close();
        if (fullDestinationPath === qgisProject.fileName) {
            logToQField(tr("LOG_RELOAD_ACTIVE"), 3);
            iface.reloadProject();
        } else {
            logToQField(tr("LOG_SAVE_NEW_MANUAL"), 0);
            iface.pushMessage(tr("BANNER_TITLE"), tr("BANNER_BODY"), 3);
        }
    }

    function startDownload() {
        if (urlInput.text === "" || dbUserInput.text === "" || dbPassInput.text === "" || filenameInput.text === "") {
            if (typeof mainWindow.displayToast !== "undefined") 
                mainWindow.displayToast(tr("TOAST_INCOMPLETE"));
            return;
        }

        pBar.visible = true;
        isSuccess = false;
        debugBox.visible = true;
        debugLog.text = tr("STATUS_INIT");

        storedUrl = urlInput.text;
        storedUser = dbUserInput.text;
        storedPass = dbPassInput.text;
        storedProject = filenameInput.text;
        saveCredentialsToJSON();

        var pureNameForDB = filenameInput.text.trim().replace(/\.qgz$/i, "").replace(/\.qgs$/i, "");
        var directoryPath = getProjectDirectory();
        fullDestinationPath = directoryPath + "/" + pureNameForDB + ".qgz";
        logToQField("Target path: " + fullDestinationPath, 3);

        var xhr = new XMLHttpRequest();
        var baseUrl = urlInput.text;
        
        if (baseUrl.indexOf("http://") !== 0 && baseUrl.indexOf("https://") !== 0) {
            baseUrl = "https://" + baseUrl;
        }
        if (!baseUrl.endsWith("/")) baseUrl += "/";

        var url = baseUrl + "get_project.php?user=" + encodeURIComponent(dbUserInput.text) 
                  + "&pass=" + encodeURIComponent(dbPassInput.text)
                  + "&file=" + encodeURIComponent(pureNameForDB);

        xhr.open("GET", url);
        xhr.responseType = "arraybuffer";

        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                pBar.visible = false;
                if (xhr.status === 200) {
                    if (xhr.response && xhr.response.byteLength > 0) {
                        
                        var isHtml = false;
                        try {
                            var checkView = new Uint8Array(xhr.response, 0, Math.min(50, xhr.response.byteLength));
                            var startText = "";
                            for (var i = 0; i < checkView.length; i++) {
                                startText += String.fromCharCode(checkView[i]);
                            }
                            if (startText.toLowerCase().indexOf("<!doc") !== -1 || startText.toLowerCase().indexOf("<html") !== -1) {
                                isHtml = true;
                            }
                        } catch(e) {
                            console.log(tr("ERR_PRE_CHECK") + e);
                        }

                        if (isHtml) {
                            logToQField(tr("ERR_HTML_REJECT"), 2);
                            statusText.text = tr("STATUS_ERR_LOGIN");
                            return; 
                        }

                        logToQField("Download sizes: " + Math.round(xhr.response.byteLength/1024) + " KB.", 3);
                        
                        if (saveToDisk(fullDestinationPath, xhr.response)) {
                            isSuccess = true;
                            statusText.text = tr("STATUS_SUCCESS");
                            infoBox.visible = true;
                        }
                    } else {
                        logToQField(tr("LOG_EMPTY_SERVER"), 1);
                    }
                } else if (xhr.status === 404) {
                    logToQField(tr("ERR_404"), 2);
                    statusText.text = tr("STATUS_ERR_DB");
                } else if (xhr.status === 401 || xhr.status === 403) {
                    logToQField(tr("ERR_AUTH"), 2);
                    statusText.text = tr("STATUS_ERR_PASS");
                } else {
                    logToQField("HTTP Error: " + xhr.status, 2);
                    statusText.text = "HTTP Error: " + xhr.status;
                }
            }
        };
        
        logToQField(tr("STATUS_CONNECT"), 0);
        xhr.send();
    }

    // =========================================================================
    // 4. BENUTZEROBERFLÄCHE (UI)
    // =========================================================================

    Component.onCompleted: {
        iface.addItemToPluginsToolbar(toolbarButton);
        

    }

    // Toolbar Button
    QfToolButton {
        id: toolbarButton
        iconSource: "icon.svg" 
        //iconColor: Theme.mainColor
        //bgcolor: Theme.darkGray
        //round: true
        onClicked: {
            isSuccess = false;
            statusText.text = tr("STATUS_READY");
            infoBox.visible = false;
            pBar.visible = false;
            debugBox.visible = true;
            
            if (initLogBuffer !== "") {
                debugLog.text = initLogBuffer;
            }
			var pName = qgisProject.fileName ? qgisProject.fileName.split('/').pop().replace(".qgz","").replace(".qgs","") : "project";
			
			if (!loadCredentialsFromJSON()) {
				storedProject = pName;
				logToQField(tr("LOG_DEFAULT_NAME"), 0);
			}            
            downloadDialog.open();
            updateUIFields();
        }
    }

    // Haupt-Dialog
    Dialog {
        id: downloadDialog
        parent: mainWindow.contentItem
        modal: true
        width: Math.min(360, mainWindow.width * 0.90)
        anchors.centerIn: parent
        standardButtons: Dialog.NoButton
        
        background: Rectangle { color: "white"; border.color: "#0078d4"; border.width: 2; radius: 8 }

        contentItem: ColumnLayout {
            id: mainCol
            anchors.margins: 15
            spacing: 8 

            Label { text: tr("TITLE"); font.bold: true; font.pointSize: 14; Layout.alignment: Qt.AlignHCenter }

            // Server-URL Eingabe
            Text { text: tr("LBL_SERVER"); color: "#666"; font.pixelSize: 11 }
            TextField { id: urlInput; text: storedUrl; Layout.fillWidth: true }

            // Login-Daten
            RowLayout {
                Layout.fillWidth: true; spacing: 8
                ColumnLayout {
                    Layout.fillWidth: true
                    Text { text: tr("LBL_USER"); color: "#666"; font.pixelSize: 11 }
                    TextField { id: dbUserInput; text: storedUser; Layout.fillWidth: true }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    Text { text: tr("LBL_PASS"); color: "#666"; font.pixelSize: 11 }
                    TextField { id: dbPassInput; text: storedPass; Layout.fillWidth: true; echoMode: TextField.Password }
                }
            }

            // Datei-Name
            Text { text: tr("LBL_PROJECT"); color: "#666"; font.pixelSize: 11 }
            TextField { id: filenameInput; text: storedProject; Layout.fillWidth: true }
            
            // Progress & Status
            ProgressBar { id: pBar; Layout.fillWidth: true; visible: false; indeterminate: true }
            Text { id: statusText; text: tr("STATUS_READY"); Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter; font.bold: true }

            // Log-Anzeige im Dialog
            Rectangle {
                id: debugBox; visible: true; Layout.fillWidth: true; Layout.preferredHeight: 80
                color: "#f0f0f0"; border.color: "#ccc"; radius: 4; clip: true
                Flickable {
                    anchors.fill: parent; contentHeight: debugLog.implicitHeight
                    ScrollBar.vertical: ScrollBar {}
                    TextEdit { id: debugLog; font.pixelSize: 9; font.family: "Monospace"; readOnly: true; padding: 5; width: parent.width; wrapMode: TextEdit.WrapAnywhere }
                }
            }

            // Erfolgs-InfoBox
            Rectangle {
                id: infoBox; visible: false; color: "#e8f5e9"; radius: 4; border.color: "#80cc28"; Layout.fillWidth: true; Layout.preferredHeight: 50
                Text { 
                    text: tr("INFO_ACTION"); 
                    color: "#2e7d32"; font.pixelSize: 10; font.bold: true; anchors.centerIn: parent; horizontalAlignment: Text.AlignHCenter 
                }
            }

            // Buttons
            RowLayout {
                Layout.fillWidth: true; Layout.topMargin: 10; spacing: 10
                Button {
                    Layout.fillWidth: true
                    text: isSuccess ? tr("BTN_RELOAD") : tr("BTN_UPDATE")
                    onClicked: isSuccess ? triggerReload() : startDownload()
                }
                Button { text: tr("BTN_CANCEL"); onClicked: downloadDialog.close() }
            }
        }
    }
}
