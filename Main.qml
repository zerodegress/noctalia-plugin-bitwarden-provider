import QtQuick
import Quickshell.Io

Item {
    property var pluginApi: null

    IpcHandler {
        function toggle() {
            pluginApi.withCurrentScreen((screen) => {
                pluginApi.toggleLauncher(screen);
            });
        }

        target: "plugin:bitwarden-provider"
    }

}
