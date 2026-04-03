import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import Qt.labs.folderlistmodel
import QtCore
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasma5support as Plasma5Support
import org.kde.plasma.extras as PlasmaExtras

/*
 * main.qml - Plasma Widget interface for Screen Profiler
 * * This file handles the UI logic, profile listing, and
 * serves as the bridge between the desktop and the shell scripts.
 */

PlasmoidItem {
    id: root


    // ============================================================================
    // Configuration & Paths
    // ============================================================================
    readonly property string baseDir:      StandardPaths.writableLocation(StandardPaths.HomeLocation).toString().replace("file://", "") + "/screenprofiler"
    readonly property string scriptPath:   baseDir + "/screenprofilercmd.sh"
    readonly property string profilesPath: baseDir + "/profiles"
    readonly property string iconPath:     "file://" + baseDir + "/resources/mainicon.png"

    // UI Scaling and Layout Constants
    readonly property int  maxVisibleProfiles: 5
    readonly property real rowHeight:          Kirigami.Units.gridUnit * 2.8
    readonly property int  panelWidth:         Kirigami.Units.gridUnit * 14

    // Navigation State
    readonly property int pageMain:       0
    readonly property int pageNewProfile: 1
    readonly property int pageSave:       2
    readonly property int pageDelete:     3
    property int currentPage: pageMain

    // Version tracking (updated when popup opens)
    property string liveVersion: "..."

    // ============================================================================
    // Internal Logic & Shell Execution
    // ============================================================================

    // Background process for fetching the version string
    Plasma5Support.DataSource {
        id: versionSource
        engine: "executable"
        onNewData: function(source, data) {
            if (data["exit code"] === 0) {
                root.liveVersion = data["stdout"].trim();
            }
            disconnectSource(source);
        }
    }

    // Main shell execution engine
    Plasma5Support.DataSource {
        id: shell
        engine: "executable"
        onNewData: function(source, data) {
            if (data["exit code"] !== 0) {
                console.error("ScreenProfiler error [" + source + "]:", data["stderr"]);
            } else {
                console.log("ScreenProfiler ok [" + source + "]:", data["stdout"]);
            }
            disconnectSource(source);
        }
        function exec(cmd) {
            console.log("ScreenProfiler exec:", cmd);
            connectSource(cmd);
        }
    }

    // Helper to format and run shell commands with escaped arguments
    function runCmd(args) {
        let cmd = args.map(a => "'" + a.replace(/'/g, "'\\''") + "'").join(" ");
        shell.exec(cmd);
    }

    // Refresh the version display whenever the user opens the widget
    onExpandedChanged: {
        if (root.expanded) {
            let cmd = "bash -c \"grep SCREENPROFILER_VERSION= '" + baseDir + "/common.sh' | cut -d= -f2 | tr -d '\\\"'\"";
            versionSource.disconnectSource(cmd);
            versionSource.connectSource(cmd);
        }
    }

    // ============================================================================
    // Data Models
    // ============================================================================

    // Watches the profiles directory for subfolders
    FolderListModel {
        id: profileModel
        folder: "file://" + root.profilesPath
        showDirs: true
        showFiles: false
        nameFilters: ["*"]
        sortField: FolderListModel.Name
        sortCaseSensitive: false
    }

    // Forces a UI refresh after file operations
    Timer {
        id: refreshTimer
        interval: 800
        onTriggered: {
            let f = profileModel.folder;
            profileModel.folder = "";
            profileModel.folder = f;
        }
    }

    // ============================================================================
    // UI Representation (Tray Icon)
    // ============================================================================
    compactRepresentation: Kirigami.Icon {
        source: root.iconPath
        active: compactMouseArea.containsMouse
        MouseArea {
            id: compactMouseArea
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: {
                root.currentPage = root.pageMain;
                root.expanded = !root.expanded;
            }
        }
    }

    // ============================================================================
    // UI Representation (Full Popup)
    // ============================================================================
    fullRepresentation: PlasmaExtras.Representation {
        implicitWidth:  root.panelWidth

        // Auto-calculate height based on which sub-page is currently visible
        implicitHeight: pageMainCol.visible       ? pageMainCol.implicitHeight
        : pageNewProfileCol.visible ? pageNewProfileCol.implicitHeight
        : pageSaveCol.visible       ? pageSaveCol.implicitHeight
        :                             pageDeleteCol.implicitHeight

        Layout.minimumWidth:  root.panelWidth
        Layout.maximumWidth:  root.panelWidth
        Layout.minimumHeight: implicitHeight
        Layout.maximumHeight: implicitHeight

        // ------------------------------------------------------------------------
        // PAGE: Main (Profile List & Navigation)
        // ------------------------------------------------------------------------
        ColumnLayout {
            id: pageMainCol
            visible: root.currentPage === root.pageMain
            anchors { top: parent.top; left: parent.left; right: parent.right }
            spacing: 0

            QQC2.ScrollView {
                Layout.fillWidth: true
                implicitHeight: Math.min(profileListContent.implicitHeight, root.maxVisibleProfiles * root.rowHeight)
                contentWidth: availableWidth
                clip: true

                ColumnLayout {
                    id: profileListContent
                    width: parent.width
                    spacing: 0

                    PlasmaComponents.Label {
                        visible: profileModel.count === 0
                        text: "No profiles saved yet"
                        opacity: 0.5
                        Layout.fillWidth: true
                        Layout.margins: Kirigami.Units.largeSpacing
                    }

                    Repeater {
                        model: profileModel
                        delegate: QQC2.ItemDelegate {
                            required property string fileName
                            text: fileName
                            icon.name: "video-display"
                            width: parent.width
                            onClicked: {
                                root.runCmd([root.scriptPath, "load", fileName]);
                                root.expanded = false;
                            }
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true;
                implicitHeight: 1;
                color: Kirigami.Theme.separatorColor;
                opacity: 0.5
            }

            // Bottom Actions
            QQC2.ItemDelegate {
                text: "Save Profile"
                icon.name: "document-save"
                Layout.fillWidth: true
                onClicked: root.currentPage = root.pageSave
            }
            QQC2.ItemDelegate {
                text: "Delete Profile"
                icon.name: "edit-delete"
                Layout.fillWidth: true
                onClicked: root.currentPage = root.pageDelete
            }

            Rectangle {
                Layout.fillWidth: true;
                implicitHeight: 1;
                color: Kirigami.Theme.separatorColor;
                opacity: 0.5
            }

            QQC2.ItemDelegate {
                text: "Settings"
                icon.name: "configure"
                Layout.fillWidth: true
                onClicked: {
                    plasmoid.internalAction("configure").trigger();
                    root.expanded = false;
                }
            }
            QQC2.ItemDelegate {
                text: "Donate"
                icon.name: "favorite"
                Layout.fillWidth: true
                onClicked: {
                    Qt.openUrlExternally("https://linktr.ee/kakiharu");
                    root.expanded = false;
                }
            }
        }

        // ------------------------------------------------------------------------
        // PAGE: New Profile (Creation Dialog)
        // ------------------------------------------------------------------------
        ColumnLayout {
            id: pageNewProfileCol
            visible: root.currentPage === root.pageNewProfile
            anchors { top: parent.top; left: parent.left; right: parent.right }
            spacing: Kirigami.Units.smallSpacing

            QQC2.ItemDelegate {
                text: "← Back"
                font.bold: true
                Layout.fillWidth: true
                onClicked: root.currentPage = root.pageSave
            }

            Rectangle {
                Layout.fillWidth: true;
                implicitHeight: 1;
                color: Kirigami.Theme.separatorColor;
                opacity: 0.5
            }

            QQC2.TextField {
                id: profileNameField
                placeholderText: "Profile name…"
                Layout.fillWidth: true
                Layout.margins: Kirigami.Units.smallSpacing
                onVisibleChanged: if (visible) forceActiveFocus()
                Keys.onReturnPressed: createBtn.clicked()
                Keys.onEscapePressed: root.currentPage = root.pageSave
            }

            QQC2.CheckBox {
                id: saveKdeCheckbox
                text: "Save KDE desktop settings"
                checked: true
                Layout.fillWidth: true
                Layout.leftMargin: Kirigami.Units.smallSpacing
            }

            QQC2.Button {
                id: createBtn
                text: "Create"
                icon.name: "document-save"
                Layout.fillWidth: true
                Layout.margins: Kirigami.Units.smallSpacing
                enabled: profileNameField.text.trim().length > 0
                onClicked: {
                    // Sanitize input: Replace spaces with underscores and strip special chars
                    let raw  = profileNameField.text.trim();
                    let name = raw.replace(/[^a-zA-Z0-9_\-. ]/g, "").replace(/ /g, "_");

                    if (name.length > 0) {
                        root.runCmd([root.scriptPath, "save", name, saveKdeCheckbox.checked ? "1" : "0"]);
                        refreshTimer.restart();
                    }
                    profileNameField.text = "";
                    root.currentPage = root.pageMain;
                    root.expanded = false;
                }
            }
        }

        // ------------------------------------------------------------------------
        // PAGE: Save Profile (Overwrite existing or create new)
        // ------------------------------------------------------------------------
        ColumnLayout {
            id: pageSaveCol
            visible: root.currentPage === root.pageSave
            anchors { top: parent.top; left: parent.left; right: parent.right }
            spacing: 0

            QQC2.ItemDelegate {
                text: "← Back"
                font.bold: true
                Layout.fillWidth: true
                onClicked: root.currentPage = root.pageMain
            }

            Rectangle {
                Layout.fillWidth: true;
                implicitHeight: 1;
                color: Kirigami.Theme.separatorColor;
                opacity: 0.5
            }

            QQC2.ItemDelegate {
                text: "New Profile…"
                icon.name: "list-add"
                Layout.fillWidth: true
                onClicked: root.currentPage = root.pageNewProfile
            }

            Rectangle {
                visible: profileModel.count > 0
                Layout.fillWidth: true;
                implicitHeight: 1;
                color: Kirigami.Theme.separatorColor;
                opacity: 0.5
            }

            // ── PAGE: Save Profile ───────────────────────────────────────────────
            Repeater {
                model: profileModel
                delegate: QQC2.ItemDelegate {
                    required property string fileName
                    text: fileName
                    icon.name: "document-save"
                    Layout.fillWidth: true
                    onClicked: {
                        // The script will now see this folder exists and check meta.json
                        // for the correct 1 or 0 automatically.
                        root.runCmd([root.scriptPath, "save", fileName, "1", "1"]);

                        refreshTimer.restart();
                        root.currentPage = root.pageMain;
                        root.expanded = false;
                    }
                }
            }
        }

        // ------------------------------------------------------------------------
        // PAGE: Delete Profile (Removal list)
        // ------------------------------------------------------------------------
        ColumnLayout {
            id: pageDeleteCol
            visible: root.currentPage === root.pageDelete
            anchors { top: parent.top; left: parent.left; right: parent.right }
            spacing: 0

            QQC2.ItemDelegate {
                text: "← Back"
                font.bold: true
                Layout.fillWidth: true
                onClicked: root.currentPage = root.pageMain
            }

            Rectangle {
                Layout.fillWidth: true;
                implicitHeight: 1;
                color: Kirigami.Theme.separatorColor;
                opacity: 0.5
            }

            PlasmaComponents.Label {
                visible: profileModel.count === 0
                text: "No profiles to delete"
                opacity: 0.5
                Layout.fillWidth: true
                Layout.margins: Kirigami.Units.largeSpacing
            }

            Repeater {
                model: profileModel
                delegate: QQC2.ItemDelegate {
                    required property string fileName
                    Layout.fillWidth: true
                    onClicked: {
                        root.runCmd([root.scriptPath, "remove", fileName]);
                        refreshTimer.restart();
                        root.currentPage = root.pageMain;
                        root.expanded = false;
                    }
                    contentItem: RowLayout {
                        spacing: Kirigami.Units.smallSpacing
                        Kirigami.Icon {
                            source: "edit-delete"
                            implicitWidth: Kirigami.Units.iconSizes.small
                            implicitHeight: Kirigami.Units.iconSizes.small
                        }
                        PlasmaComponents.Label {
                            text: fileName
                            color: "#ff4444" // Visual warning for deletion
                            Layout.fillWidth: true
                        }
                    }
                }
            }
        }
    }
}
