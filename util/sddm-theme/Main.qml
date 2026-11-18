// Login screen in hyprlock's layout (dot_config/hypr/hyprlock.conf), in the
// colours and wallpaper of the desktop theme. Those come from theme.conf.user,
// a link to /var/lib/sddm-theme/theme.conf that theme-set rewrites.
import QtQuick

Rectangle {
    id: root
    width: 1920
    height: 1080
    color: config.base

    // hyprlock's sizes are for a 1080p screen. The greeter runs on Xorg at
    // scale 1, so scale up on bigger screens (2880x1920: 1.78, close to the
    // 1.875 Hyprland uses there).
    readonly property real s: Math.max(1, height / 1080)
    // hyprlock font sizes are points (at 96 dpi)
    function pt(size) { return Math.round(size * 4 / 3 * s) }

    property string user: userModel.lastUser
    property int attempts: 0
    property bool failed: false
    property bool busy: false
    property date now: new Date()

    function login() {
        if (busy || user === "")
            return
        busy = true
        sddm.login(user, password.text, sessionModel.lastIndex)
    }

    function layoutName() {
        var l = keyboard.layouts[keyboard.currentLayout]
        return l ? l.longName : ""
    }

    Connections {
        target: sddm
        function onLoginFailed() {
            root.busy = false
            root.failed = true
            root.attempts += 1
            password.text = ""
            password.forceActiveFocus()
        }
    }

    // Nobody logged in before (fresh install): take the first user
    Repeater {
        model: userModel
        Item { Component.onCompleted: if (index === 0 && root.user === "") root.user = model.name }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.now = new Date()
    }

    Image {
        anchors.fill: parent
        source: config.background ? "file://" + config.background : ""
        fillMode: Image.PreserveAspectCrop
        sourceSize: Qt.size(width, height)
        asynchronous: true
    }

    // LAYOUT
    Text {
        x: 30 * root.s
        y: 30 * root.s
        text: root.layoutName() ? "Layout: " + root.layoutName() : ""
        color: config.text
        font.family: config.font
        font.pixelSize: root.pt(25)
    }

    // TIME
    Text {
        anchors.right: parent.right
        anchors.rightMargin: 30 * root.s
        anchors.top: parent.top
        text: Qt.formatTime(root.now, "HH:mm")
        color: config.text
        font.family: config.font
        font.pixelSize: root.pt(90)
    }

    // DATE
    Text {
        anchors.right: parent.right
        anchors.rightMargin: 30 * root.s
        y: 150 * root.s
        text: Qt.formatDate(root.now, "dddd, dd MMMM yyyy")
        color: config.text
        font.family: config.font
        font.pixelSize: root.pt(25)
    }

    // INPUT FIELD
    Rectangle {
        id: field
        width: 300 * root.s
        height: 60 * root.s
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: 47 * root.s
        radius: height / 2
        color: config.surface
        border.width: 4 * root.s
        border.color: root.failed ? config.red : keyboard.capsLock ? config.yellow : config.accent

        // The typed text stays invisible: the dots below stand for it
        TextInput {
            id: password
            anchors.fill: parent
            echoMode: TextInput.Password
            color: "transparent"
            selectionColor: "transparent"
            selectedTextColor: "transparent"
            cursorDelegate: Item {}
            focus: true
            onTextChanged: if (text !== "") root.failed = false
            onAccepted: root.login()
        }

        Row {
            id: dots
            readonly property real size: field.height * 0.2
            anchors.centerIn: parent
            spacing: size * 0.2
            Repeater {
                // As many as fit (width is 0 during startup)
                model: Math.max(0, Math.min(password.length,
                                            Math.floor((field.width - field.height) / (dots.size * 1.2))))
                Rectangle {
                    width: dots.size
                    height: dots.size
                    radius: dots.size / 2
                    color: config.text
                }
            }
        }

        Text {
            anchors.centerIn: parent
            visible: password.length === 0
            textFormat: Text.StyledText
            color: config.text
            font.family: config.font
            font.pixelSize: root.pt(15)
            text: root.failed
                ? "<i>Login failed <b>(" + root.attempts + ")</b></i>"
                : "<i>" + String.fromCodePoint(0xF033E) + " Log in as </i><font color=\"" + config.accent + "\">"
                  + root.user + "</font>"
        }
    }

    // Not in hyprlock: suspend, reboot and power off
    component PowerButton: Text {
        id: button
        property var action
        color: mouse.containsMouse ? config.accent : config.text
        font.family: config.font
        font.pixelSize: root.pt(25)
        MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: button.action()
        }
    }

    Row {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 30 * root.s
        spacing: 30 * root.s
        PowerButton { text: String.fromCodePoint(0xF04B2); visible: sddm.canSuspend; action: () => sddm.suspend() }
        PowerButton { text: String.fromCodePoint(0xF0709); visible: sddm.canReboot; action: () => sddm.reboot() }
        PowerButton { text: String.fromCodePoint(0xF0425); visible: sddm.canPowerOff; action: () => sddm.powerOff() }
    }

    Component.onCompleted: password.forceActiveFocus()
}
