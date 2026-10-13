import QtQuick

import qs.style

Rectangle {
    id: root

    property var frame: null
    readonly property bool shown: !!frame && (frame.spill || !frame.fill)

    property var held: null
    onFrameChanged: if (frame)
        held = frame

    property bool ready: false
    onHeldChanged: if (held && !ready)
        Qt.callLater(() => root.ready = true)

    opacity: shown ? 1 : 0
    visible: opacity > 0
    x: held?.vx ?? 0
    y: held?.vy ?? 0
    width: held?.vw ?? 0
    height: held?.vh ?? 0
    radius: held?.vpRadius ?? 0
    color: Colors.md3.surface_container_lowest
    border.width: 1
    border.color: Qt.alpha(Colors.md3.primary, 0.5)

    Behavior on opacity {
        enabled: root.ready
        NumberAnimation {
            duration: 200
            easing.type: Easing.OutCubic
        }
    }
    Behavior on x {
        enabled: root.ready
        NumberAnimation {
            duration: 320
            easing.type: Easing.OutCubic
        }
    }
    Behavior on y {
        enabled: root.ready
        NumberAnimation {
            duration: 320
            easing.type: Easing.OutCubic
        }
    }
    Behavior on width {
        enabled: root.ready
        NumberAnimation {
            duration: 320
            easing.type: Easing.OutCubic
        }
    }
    Behavior on height {
        enabled: root.ready
        NumberAnimation {
            duration: 320
            easing.type: Easing.OutCubic
        }
    }
    Behavior on radius {
        enabled: root.ready
        NumberAnimation {
            duration: 320
            easing.type: Easing.OutCubic
        }
    }
}
