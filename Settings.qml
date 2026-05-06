import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Widgets

ColumnLayout {
    id: root

    property var pluginApi: null
    property var defaults: pluginApi && pluginApi.manifest && pluginApi.manifest.metadata ? pluginApi.manifest.metadata.defaultSettings || ({
    }) : ({
    })
    property var settings: pluginApi && pluginApi.pluginSettings ? pluginApi.pluginSettings : ({
    })
    property string editRbwCommand: settings.rbwCommand || defaults.rbwCommand || "rbw"
    property string editProfile: settings.profile || defaults.profile || ""
    property string editBaseUrl: settings.baseUrl || defaults.baseUrl || ""
    property string editIdentityUrl: settings.identityUrl || defaults.identityUrl || ""
    property string editEmail: settings.email || defaults.email || ""
    property string editPinentry: settings.pinentry || defaults.pinentry || ""
    property string editLockTimeout: settings.lockTimeout || defaults.lockTimeout || ""
    property string editSyncInterval: settings.syncInterval || defaults.syncInterval || ""
    property bool editAutoApplyConfig: settings.autoApplyConfig !== undefined ? settings.autoApplyConfig : (defaults.autoApplyConfig !== undefined ? defaults.autoApplyConfig : true)
    property bool editIncludeInSearch: settings.includeInSearch !== undefined ? settings.includeInSearch : (defaults.includeInSearch !== undefined ? defaults.includeInSearch : false)
    property string editCopyField: settings.copyField || defaults.copyField || "password"
    property string editMaxResults: String(settings.maxResults || defaults.maxResults || 50)

    function saveSettings() {
        pluginApi.pluginSettings.rbwCommand = root.editRbwCommand.trim() || "rbw";
        pluginApi.pluginSettings.profile = root.editProfile.trim();
        pluginApi.pluginSettings.baseUrl = root.editBaseUrl.trim();
        pluginApi.pluginSettings.identityUrl = root.editIdentityUrl.trim();
        pluginApi.pluginSettings.email = root.editEmail.trim();
        pluginApi.pluginSettings.pinentry = root.editPinentry.trim();
        pluginApi.pluginSettings.lockTimeout = root.editLockTimeout.trim();
        pluginApi.pluginSettings.syncInterval = root.editSyncInterval.trim();
        pluginApi.pluginSettings.autoApplyConfig = root.editAutoApplyConfig;
        pluginApi.pluginSettings.includeInSearch = root.editIncludeInSearch;
        pluginApi.pluginSettings.copyField = root.editCopyField.trim() || "password";
        pluginApi.pluginSettings.maxResults = parseInt(root.editMaxResults) || 50;
        pluginApi.saveSettings();
    }

    spacing: Style.marginL

    ColumnLayout {
        Layout.fillWidth: true
        spacing: Style.marginM

        NLabel {
            label: pluginApi.tr("settings.rbwCommand.label")
            description: pluginApi.tr("settings.rbwCommand.description")
        }

        NTextInput {
            Layout.fillWidth: true
            placeholderText: "rbw"
            text: root.editRbwCommand
            onTextChanged: root.editRbwCommand = text
        }

        NLabel {
            label: pluginApi.tr("settings.profile.label")
            description: pluginApi.tr("settings.profile.description")
        }

        NTextInput {
            Layout.fillWidth: true
            placeholderText: "work"
            text: root.editProfile
            onTextChanged: root.editProfile = text
        }

        NCheckbox {
            Layout.fillWidth: true
            label: pluginApi.tr("settings.includeInSearch.label")
            description: pluginApi.tr("settings.includeInSearch.description")
            checked: root.editIncludeInSearch
            onToggled: (checked) => {
                return root.editIncludeInSearch = checked;
            }
        }

    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: Style.marginM

        NCheckbox {
            Layout.fillWidth: true
            label: pluginApi.tr("settings.autoApplyConfig.label")
            description: pluginApi.tr("settings.autoApplyConfig.description")
            checked: root.editAutoApplyConfig
            onToggled: (checked) => {
                return root.editAutoApplyConfig = checked;
            }
        }

        NLabel {
            label: pluginApi.tr("settings.email.label")
            description: pluginApi.tr("settings.email.description")
        }

        NTextInput {
            Layout.fillWidth: true
            placeholderText: "user@example.com"
            text: root.editEmail
            onTextChanged: root.editEmail = text
        }

        NLabel {
            label: pluginApi.tr("settings.baseUrl.label")
            description: pluginApi.tr("settings.baseUrl.description")
        }

        NTextInput {
            Layout.fillWidth: true
            placeholderText: "https://api.bitwarden.com/"
            text: root.editBaseUrl
            onTextChanged: root.editBaseUrl = text
        }

        NLabel {
            label: pluginApi.tr("settings.identityUrl.label")
            description: pluginApi.tr("settings.identityUrl.description")
        }

        NTextInput {
            Layout.fillWidth: true
            placeholderText: "https://identity.bitwarden.com/"
            text: root.editIdentityUrl
            onTextChanged: root.editIdentityUrl = text
        }

    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: Style.marginM

        NLabel {
            label: pluginApi.tr("settings.copyField.label")
            description: pluginApi.tr("settings.copyField.description")
        }

        NTextInput {
            Layout.fillWidth: true
            placeholderText: "password"
            text: root.editCopyField
            onTextChanged: root.editCopyField = text
        }

        NLabel {
            label: pluginApi.tr("settings.maxResults.label")
            description: pluginApi.tr("settings.maxResults.description")
        }

        NTextInput {
            Layout.fillWidth: true
            placeholderText: "50"
            text: root.editMaxResults
            onTextChanged: root.editMaxResults = text
        }

        NLabel {
            label: pluginApi.tr("settings.lockTimeout.label")
            description: pluginApi.tr("settings.lockTimeout.description")
        }

        NTextInput {
            Layout.fillWidth: true
            placeholderText: "3600"
            text: root.editLockTimeout
            onTextChanged: root.editLockTimeout = text
        }

        NLabel {
            label: pluginApi.tr("settings.syncInterval.label")
            description: pluginApi.tr("settings.syncInterval.description")
        }

        NTextInput {
            Layout.fillWidth: true
            placeholderText: "3600"
            text: root.editSyncInterval
            onTextChanged: root.editSyncInterval = text
        }

        NLabel {
            label: pluginApi.tr("settings.pinentry.label")
            description: pluginApi.tr("settings.pinentry.description")
        }

        NTextInput {
            Layout.fillWidth: true
            placeholderText: "pinentry"
            text: root.editPinentry
            onTextChanged: root.editPinentry = text
        }

    }

}
