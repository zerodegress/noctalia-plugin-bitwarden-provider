import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Services.UI

Item {
    id: root

    property var pluginApi: null
    property string name: "Bitwarden"
    property var launcher: null
    property bool handleSearch: false
    property string supportedLayouts: "list"
    property bool supportsAutoPaste: false
    property bool ignoreDensity: false
    property string commandPrefix: ">bw"
    property int maxResults: 50
    property string selectedCategory: "all"
    property var categories: ["all", "password", "username", "totp", "notes"]
    property var categoryIcons: ({
        "all": "key",
        "password": "lock",
        "username": "user",
        "totp": "number",
        "notes": "notes"
    })
    property var entries: []
    property bool loaded: false
    property bool loading: false
    property bool checkingUnlock: false
    property bool locked: false
    property bool configApplied: false
    property string lastError: ""
    property string lastQuery: ""
    property string pendingAction: ""

    function init() {
        name = pluginApi ? pluginApi.tr("launcher.title") : "Bitwarden";
        const defaults = pluginApi && pluginApi.manifest && pluginApi.manifest.metadata ? pluginApi.manifest.metadata.defaultSettings || {
        } : {
        };
        handleSearch = setting("includeInSearch", defaults.includeInSearch) === true;
        maxResults = parseInt(setting("maxResults", defaults.maxResults || 50)) || 50;
        commandPrefix = ">" + (pluginApi && pluginApi.manifest && pluginApi.manifest.metadata ? pluginApi.manifest.metadata.commandPrefix || "bw" : "bw");
    }

    function onOpened() {
        selectedCategory = "all";
        locked = false;
    }

    function selectCategory(category) {
        selectedCategory = category;
        if (launcher)
            launcher.updateResults();

    }

    function getCategoryName(category) {
        const names = {
            "all": pluginApi.tr("categories.all"),
            "password": pluginApi.tr("categories.password"),
            "username": pluginApi.tr("categories.username"),
            "totp": pluginApi.tr("categories.totp"),
            "notes": pluginApi.tr("categories.notes")
        };
        return names[category] || category;
    }

    function setting(key, fallback) {
        const settings = pluginApi && pluginApi.pluginSettings ? pluginApi.pluginSettings : {
        };
        return settings[key] !== undefined ? settings[key] : fallback;
    }

    function rbwCommand() {
        return setting("rbwCommand", "rbw") || "rbw";
    }

    function shellQuote(value) {
        const text = String(value === undefined || value === null ? "" : value);
        return "'" + text.replace(/'/g, "'\\''") + "'";
    }

    function envPrefix() {
        const profile = setting("profile", "");
        return profile ? "RBW_PROFILE=" + shellQuote(profile) + " " : "";
    }

    function rbwBase() {
        return envPrefix() + shellQuote(rbwCommand());
    }

    function configCommand(key, value) {
        if (!value)
            return "";

        return rbwBase() + " config set " + key + " " + shellQuote(value) + " >/dev/null";
    }

    function configPrelude(force) {
        if (setting("autoApplyConfig", true) !== true)
            return "";

        if (configApplied && !force)
            return "";

        const commands = [configCommand("email", setting("email", "")), configCommand("base_url", setting("baseUrl", "")), configCommand("identity_url", setting("identityUrl", "")), configCommand("pinentry", setting("pinentry", "")), configCommand("lock_timeout", setting("lockTimeout", "")), configCommand("sync_interval", setting("syncInterval", ""))].filter((command) => {
            return command.length > 0;
        });
        if (commands.length > 0)
            configApplied = true;

        return commands.length > 0 ? commands.join(" && ") + " && " : "";
    }

    function rbwShell(args, applyConfig) {
        return (applyConfig ? configPrelude(false) : "") + rbwBase() + " " + args;
    }

    function handleCommand(searchText) {
        return searchText.trim().startsWith(commandPrefix);
    }

    function commands() {
        return [{
            "name": commandPrefix,
            "description": pluginApi.tr("launcher.description"),
            "icon": "key",
            "isTablerIcon": true,
            "isImage": false,
            "onActivate": function() {
                launcher.setSearchText(commandPrefix + " ");
            }
        }];
    }

    function getResults(searchText) {
        const trimmed = searchText.trim();
        const commandMode = trimmed.startsWith(commandPrefix);
        if (!commandMode) {
            if (!handleSearch || trimmed.length < 2 || loading)
                return [];

            return searchEntries(trimmed.toLowerCase(), setting("copyField", "password"));
        }
        const query = trimmed.slice(commandPrefix.length).trim();
        if (query === "sync")
            return [commandEntry("sync", pluginApi.tr("launcher.sync.title"), pluginApi.tr("launcher.sync.description"), "refresh")];

        if (query === "lock")
            return [commandEntry("lock", pluginApi.tr("launcher.lock.title"), pluginApi.tr("launcher.lock.description"), "lock-off")];

        if (query === "refresh") {
            checkUnlocked("", true);
            return checkingUnlockResult();
        }
        const field = selectedCategory === "all" ? setting("copyField", "password") : selectedCategory;
        if (locked)
            return lockedResult();

        if (!loaded && !loading && !checkingUnlock)
            checkUnlocked(query, false);
        else if (query !== lastQuery && !loading)
            lastQuery = query;
        if (checkingUnlock)
            return checkingUnlockResult();

        if (loading)
            return loadingResult();

        if (lastError)
            return errorResult();

        if (!loaded)
            return initialResult();

        const results = searchEntries(query.toLowerCase(), field);
        return query ? results : controlEntries().concat(results);
    }

    function checkUnlocked(query, force) {
        if (unlockCheckProcess.running || listProcess.running)
            return ;

        if (loaded && !force) {
            lastQuery = query;
            return ;
        }
        checkingUnlock = true;
        locked = false;
        loaded = false;
        lastError = "";
        lastQuery = query;
        unlockCheckProcess.command = ["sh", "-c", rbwShell("unlocked", false)];
        unlockCheckProcess.running = true;
    }

    function handleUnlockCheckFinished(exitCode) {
        checkingUnlock = false;
        if (exitCode === 0) {
            locked = false;
            configApplied = true;
            fetchEntries(lastQuery, true);
            return ;
        }
        locked = true;
        loaded = false;
        entries = [];
        if (launcher)
            launcher.updateResults();

    }

    function fetchEntries(query, force) {
        if (listProcess.running)
            return ;

        if (loaded && !force) {
            lastQuery = query;
            return ;
        }
        loading = true;
        loaded = false;
        locked = false;
        lastError = "";
        lastQuery = query;
        listProcess.command = ["sh", "-c", rbwShell("list --fields id,name,user,folder,type", true)];
        listProcess.running = true;
    }

    function parseListResults(exitCode) {
        loading = false;
        if (exitCode !== 0) {
            loaded = false;
            lastError = listProcess.stderr.text || pluginApi.tr("launcher.error.description");
            Logger.e("BitwardenProvider", "rbw list failed:", lastError);
            if (launcher)
                launcher.updateResults();

            return ;
        }
        entries = listProcess.stdout.text.split("\n").filter((line) => {
            return line.trim().length > 0;
        }).map(parseEntryLine).filter((entry) => {
            return entry.name.length > 0;
        });
        loaded = true;
        lastError = "";
        if (launcher)
            launcher.updateResults();

    }

    function parseEntryLine(line) {
        const parts = line.split("\t");
        return {
            "id": parts[0] || "",
            "name": parts[1] || "",
            "user": parts[2] || "",
            "folder": parts[3] || "",
            "type": parts[4] || ""
        };
    }

    function searchEntries(query, field) {
        let source = entries;
        if (query) {
            if (typeof FuzzySort !== "undefined")
                source = FuzzySort.go(query, entries, {
                "limit": maxResults,
                "keys": ["name", "user", "folder"]
            }).map((result) => {
                return result.obj;
            });
            else
                source = entries.filter((entry) => {
                return entryMatches(entry, query);
            }).slice(0, maxResults);
        } else {
            source = entries.slice(0, maxResults);
        }
        return source.map((entry) => {
            return formatEntry(entry, field);
        });
    }

    function entryMatches(entry, query) {
        return [entry.name, entry.user, entry.folder, entry.type].join(" ").toLowerCase().indexOf(query) !== -1;
    }

    function formatEntry(entry, field) {
        const effectiveField = field || "password";
        const descriptionParts = [];
        if (entry.user)
            descriptionParts.push(entry.user);

        if (entry.folder)
            descriptionParts.push(entry.folder);

        if (entry.type)
            descriptionParts.push(entry.type);

        return {
            "name": entry.name,
            "description": descriptionParts.join("  |  "),
            "icon": iconForField(effectiveField),
            "isTablerIcon": true,
            "isImage": false,
            "badgeIcon": entry.folder ? "folder" : "",
            "singleLine": true,
            "provider": root,
            "usageKey": "bitwarden:" + entry.id,
            "onActivate": function() {
                copyEntryField(entry, effectiveField);
                launcher.close();
            }
        };
    }

    function iconForField(field) {
        if (field === "username")
            return "user";

        if (field === "totp")
            return "number";

        if (field === "notes")
            return "notes";

        return "lock";
    }

    function commandEntry(action, title, description, icon) {
        return {
            "name": title,
            "description": description,
            "icon": icon,
            "isTablerIcon": true,
            "isImage": false,
            "onActivate": function() {
                runAction(action);
                launcher.close();
            }
        };
    }

    function controlEntries() {
        return [commandEntry("lock", pluginApi.tr("launcher.lock.title"), pluginApi.tr("launcher.lock.description"), "lock-off"), commandEntry("sync", pluginApi.tr("launcher.sync.title"), pluginApi.tr("launcher.sync.description"), "refresh")];
    }

    function runAction(action) {
        if (actionProcess.running)
            return ;

        pendingAction = action;
        const args = action === "sync" ? "sync" : "lock";
        actionProcess.command = ["sh", "-c", rbwShell(args, action === "sync")];
        actionProcess.running = true;
    }

    function unlockFromLauncher() {
        if (launcher) {
            if (launcher.closeImmediately)
                launcher.closeImmediately();
            else
                launcher.close();
        }
        unlockDelayTimer.restart();
    }

    function runUnlock() {
        locked = false;
        loaded = false;
        Quickshell.execDetached(["sh", "-c", rbwShell("unlock", true)]);
    }

    function copyEntryField(entry, field) {
        if (actionProcess.running)
            return ;

        pendingAction = "copy";
        let args = "get --clipboard ";
        if (field && field !== "password")
            args += "--field " + shellQuote(field) + " ";

        args += shellQuote(entry.id || entry.name);
        actionProcess.command = ["sh", "-c", rbwShell(args, false)];
        actionProcess.running = true;
    }

    function handleActionFinished(exitCode) {
        if (exitCode !== 0) {
            Logger.e("BitwardenProvider", "rbw action failed:", actionProcess.stderr.text);
            ToastService.showError(pluginApi.tr("launcher.title"), actionProcess.stderr.text || pluginApi.tr("launcher.action.error"));
            return ;
        }
        if (pendingAction === "copy") {
            ToastService.showNotice(pluginApi.tr("launcher.title"), pluginApi.tr("launcher.action.copied"));
        } else if (pendingAction === "sync") {
            loaded = false;
            fetchEntries(lastQuery, true);
            ToastService.showNotice(pluginApi.tr("launcher.title"), pluginApi.tr("launcher.sync.done"));
        } else if (pendingAction === "lock") {
            loaded = false;
            locked = true;
            entries = [];
            ToastService.showNotice(pluginApi.tr("launcher.title"), pluginApi.tr("launcher.lock.done"));
        }
    }

    function checkingUnlockResult() {
        return [{
            "name": pluginApi.tr("launcher.checking.title"),
            "description": pluginApi.tr("launcher.checking.description"),
            "icon": "refresh",
            "isTablerIcon": true,
            "isImage": false,
            "onActivate": function() {
            }
        }];
    }

    function lockedResult() {
        return [{
            "name": pluginApi.tr("launcher.unlock.title"),
            "description": pluginApi.tr("launcher.unlock.description"),
            "icon": "key",
            "isTablerIcon": true,
            "isImage": false,
            "onActivate": function() {
                unlockFromLauncher();
            }
        }];
    }

    function loadingResult() {
        return [{
            "name": pluginApi.tr("launcher.loading.title"),
            "description": pluginApi.tr("launcher.loading.description"),
            "icon": "refresh",
            "isTablerIcon": true,
            "isImage": false,
            "onActivate": function() {
            }
        }];
    }

    function initialResult() {
        return [{
            "name": pluginApi.tr("launcher.initial.title"),
            "description": pluginApi.tr("launcher.initial.description"),
            "icon": "key",
            "isTablerIcon": true,
            "isImage": false,
            "onActivate": function() {
                checkUnlocked("", true);
            }
        }];
    }

    function errorResult() {
        return [{
            "name": pluginApi.tr("launcher.error.title"),
            "description": lastError,
            "icon": "alert-circle",
            "isTablerIcon": true,
            "isImage": false,
            "onActivate": function() {
                checkUnlocked(lastQuery, true);
            }
        }];
    }

    Timer {
        id: unlockDelayTimer

        interval: 150
        repeat: false
        onTriggered: root.runUnlock()
    }

    Process {
        id: unlockCheckProcess

        command: ["sh", "-c", ""]
        onExited: (exitCode) => {
            return root.handleUnlockCheckFinished(exitCode);
        }

        stdout: StdioCollector {
        }

        stderr: StdioCollector {
        }

    }

    Process {
        id: listProcess

        command: ["sh", "-c", ""]
        onExited: (exitCode) => {
            return root.parseListResults(exitCode);
        }

        stdout: StdioCollector {
        }

        stderr: StdioCollector {
        }

    }

    Process {
        id: actionProcess

        command: ["sh", "-c", ""]
        onExited: (exitCode) => {
            return root.handleActionFinished(exitCode);
        }

        stdout: StdioCollector {
        }

        stderr: StdioCollector {
        }

    }

}
