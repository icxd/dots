import QtQuick

// shinrai · SDDM login screen
//
// The same picture as the desktop and the lock screen: the wallpaper, and the
// white island at the top showing the time. Type your password and the island
// fills with dots; Enter logs you in. A wrong password shakes it and says so.
//
//   Enter  log in · Esc  clear · Tab  next user (if there are several)
//   bottom row: click your name / the session to switch, or restart / shut down
//
// The greeter draws in the screen's real pixels, so every size is multiplied
// by `scale` from theme.conf: your monitors' scale in hyprland.lua (install.sh
// fills it in). That keeps the island the same size as on the desktop. With
// several screens, the island is on the main one; the others show the wallpaper.
// Try it without logging out:
//   sddm-greeter-qt6 --test-mode --theme /usr/share/sddm/themes/shinrai
Rectangle {
    id: root

    width: 1720
    height: 720
    color: "#000000"

    readonly property real s: Math.max(0.5, Number(config.scale) || 1)
    readonly property string font: "Inter"
    readonly property string iconFont: "JetBrainsMono Nerd Font"

    // ---- who logs in, into what ----
    property int userIndex: Math.max(0, userModel.lastIndex)
    property int sessionIndex: Math.max(0, sessionModel.lastIndex)

    readonly property Item user: users.count > 0 ? users.itemAt(Math.min(userIndex, users.count - 1)) : null
    readonly property string userName: user ? user.name : userModel.lastUser
    readonly property string userLabel: user ? (user.realName !== "" ? user.realName : user.name) : userModel.lastUser
    readonly property string sessionName: sessions.count > 0 && sessions.itemAt(sessionIndex)
                                          ? sessions.itemAt(sessionIndex).name : ""

    Repeater {
        id: users
        model: userModel
        delegate: Item {
            required property string name
            required property string realName
        }
    }

    Repeater {
        id: sessions
        model: sessionModel
        delegate: Item {
            required property string name
        }
    }

    // ---- what the island shows ----
    //   idle · typing · checking · failed · message · done
    property string mode: "idle"
    property string message: ""

    function login() {
        if (mode === "checking" || mode === "done") return;
        if (password.length === 0) {
            shake.restart();
            return;
        }
        mode = "checking";
        sddm.login(userName, password.text, sessionIndex);
    }

    function cycleUser(step) {
        if (users.count < 2) return;
        userIndex = (userIndex + step + users.count) % users.count;
        password.clear();
    }

    function cycleSession() {
        if (sessions.count < 2) return;
        sessionIndex = (sessionIndex + 1) % sessions.count;
    }

    Connections {
        target: sddm

        function onLoginFailed() {
            const keepMessage = root.mode === "message";
            password.clear();
            root.mode = keepMessage ? "message" : "failed";
            shake.restart();
            settle.restart();
        }

        function onLoginSucceeded() {
            root.mode = "done";
        }

        // PAM notices, e.g. "account locked for 10 minutes"
        function onInformationMessage(message) {
            root.message = message;
            root.mode = "message";
            settle.restart();
        }
    }

    // a failure / notice shows for a moment, then the time comes back
    Timer {
        id: settle
        interval: 2200
        onTriggered: if (root.mode === "failed" || root.mode === "message")
                         root.mode = password.length > 0 ? "typing" : "idle"
    }

    // the clock
    property date now: new Date()
    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.now = new Date()
    }

    // ---- the wallpaper ----
    Image {
        anchors.fill: parent
        source: config.background ? Qt.resolvedUrl(config.background) : Qt.resolvedUrl("background.png")
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        smooth: true
        mipmap: true
        opacity: status === Image.Ready ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 700; easing.type: Easing.OutCubic } }
    }

    // a click anywhere brings the typing back
    MouseArea {
        anchors.fill: parent
        onClicked: password.forceActiveFocus()
    }

    // The password goes here; it's never shown, the island draws dots for it.
    TextInput {
        id: password
        width: 1
        height: 1
        opacity: 0
        echoMode: TextInput.Password
        focus: true
        enabled: root.mode !== "checking" && root.mode !== "done"

        onTextChanged: {
            if (root.mode === "idle" || root.mode === "typing"
                    || ((root.mode === "failed" || root.mode === "message") && length > 0))
                root.mode = length > 0 ? "typing" : "idle";
        }

        Keys.onPressed: event => {
            switch (event.key) {
            case Qt.Key_Return:
            case Qt.Key_Enter: root.login(); break;
            case Qt.Key_Escape: password.clear(); break;
            case Qt.Key_Tab: root.cycleUser(1); break;
            case Qt.Key_Backtab: root.cycleUser(-1); break;
            default: return;
            }
            event.accepted = true;
        }
    }

    // ---- everything on top of the wallpaper ----
    Item {
        id: ui
        anchors.fill: parent
        visible: primaryScreen

        // fades in at the start, and out once you're logged in
        property real entrance: 0
        property real leaving: root.mode === "done" ? 0 : 1
        opacity: entrance * leaving

        NumberAnimation on entrance { from: 0; to: 1; duration: 600; easing.type: Easing.OutCubic }
        Behavior on leaving { NumberAnimation { duration: 450; easing.type: Easing.InOutQuad } }

        // ---- the island ----
        Spring {
            id: islandWidth
            from: 32 * root.s
            target: {
                const s = root.s;
                switch (root.mode) {
                case "typing":
                case "checking": return Math.max(108 * s, dots.implicitWidth + 48 * s);
                case "failed":
                case "message": return Math.min(root.width * 0.6, note.implicitWidth + 52 * s);
                case "done": return 32 * s;
                default: return Math.max(108 * s, time.implicitWidth + 48 * s);
                }
            }
            response: 0.45
            damping: 0.75
            epsilon: 0.05
        }

        Rectangle {
            id: island
            anchors.horizontalCenter: parent.horizontalCenter
            y: 8 * root.s
            width: islandWidth.value
            height: 32 * root.s
            radius: height / 2
            color: root.mode === "checking" ? "#e4e4e7" : keyboard.capsLock ? "#e9e9ec" : "#ffffff"
            clip: true
            transform: Translate { id: nudge }

            Behavior on color { ColorAnimation { duration: 200 } }

            Text {
                id: time
                anchors.centerIn: parent
                text: Qt.formatTime(root.now, "HH:mm")
                color: "#0b0b0c"
                font.family: root.font
                font.pixelSize: Math.round(14 * root.s)
                font.weight: Font.DemiBold
                font.features: ({ "tnum": 1 })
                opacity: root.mode === "idle" ? 1 : 0
                scale: root.mode === "idle" ? 1 : 0.9
                Behavior on opacity { NumberAnimation { duration: 180 } }
                Behavior on scale { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
            }

            Row {
                id: dots
                anchors.centerIn: parent
                spacing: 5 * root.s
                opacity: root.mode === "typing" || root.mode === "checking" ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 160 } }

                Repeater {
                    model: Math.min(password.length, 16)

                    Rectangle {
                        width: 7 * root.s
                        height: width
                        radius: width / 2
                        color: "#0b0b0c"
                        NumberAnimation on scale { from: 0.2; to: 1; duration: 220; easing.type: Easing.OutBack }
                    }
                }
            }

            Text {
                id: note
                anchors.centerIn: parent
                width: Math.min(implicitWidth, root.width * 0.6 - 52 * root.s)
                text: root.mode === "message" ? root.message : "Wrong password"
                color: "#0b0b0c"
                font.family: root.font
                font.pixelSize: Math.round(13 * root.s)
                font.weight: Font.DemiBold
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignHCenter
                opacity: root.mode === "failed" || root.mode === "message" ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 180 } }
            }
        }

        // like the iPhone: a wrong password shakes the island
        SequentialAnimation {
            id: shake
            NumberAnimation { target: nudge; property: "x"; to: -10 * root.s; duration: 45; easing.type: Easing.OutQuad }
            NumberAnimation { target: nudge; property: "x"; to: 9 * root.s; duration: 80; easing.type: Easing.InOutQuad }
            NumberAnimation { target: nudge; property: "x"; to: -6 * root.s; duration: 70; easing.type: Easing.InOutQuad }
            NumberAnimation { target: nudge; property: "x"; to: 3 * root.s; duration: 60; easing.type: Easing.InOutQuad }
            NumberAnimation { target: nudge; property: "x"; to: 0; duration: 60; easing.type: Easing.OutQuad }
        }

        // the date, quietly under it
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            y: 49 * root.s
            text: Qt.formatDate(root.now, "dddd d MMMM")
            color: "#8cffffff"
            font.family: root.font
            font.pixelSize: Math.round(12 * root.s)
        }

        // ---- bottom row: user · session · restart · shut down ----
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 18 * root.s
            spacing: 18 * root.s

            BottomText {
                text: root.userLabel
                s: root.s
                textFont: root.font
                glyphFont: root.iconFont
                anchors.verticalCenter: parent.verticalCenter
                clickable: users.count > 1
                onClicked: { root.cycleUser(1); password.forceActiveFocus(); }
            }

            BottomText {
                visible: root.sessionName !== ""
                text: root.sessionName
                s: root.s
                textFont: root.font
                glyphFont: root.iconFont
                anchors.verticalCenter: parent.verticalCenter
                clickable: sessions.count > 1
                onClicked: { root.cycleSession(); password.forceActiveFocus(); }
            }

            BottomText {
                visible: sddm.canReboot
                text: String.fromCodePoint(0xf0709)
                s: root.s
                textFont: root.font
                glyphFont: root.iconFont
                anchors.verticalCenter: parent.verticalCenter
                glyph: true
                onClicked: sddm.reboot()
            }

            BottomText {
                visible: sddm.canPowerOff
                text: String.fromCodePoint(0xf0425)
                s: root.s
                textFont: root.font
                glyphFont: root.iconFont
                anchors.verticalCenter: parent.verticalCenter
                glyph: true
                onClicked: sddm.powerOff()
            }
        }
    }

    // Take the keyboard once the screen is up: while the theme loads it isn't
    // in a window yet, so asking right away can go nowhere.
    Component.onCompleted: password.forceActiveFocus()
    Timer {
        interval: 150
        running: true
        onTriggered: password.forceActiveFocus()
    }
}
