import QtQuick
import Quickshell
import QtQuick.Shapes
import QtQuick.Effects
import Quickshell.Io
import "MaterialIconCache.js" as IconCache

Item {
    id: root

    property string name: ""
    property bool filled: false
    property color color: "white"
    property real iconSize: 24
    property int transitionDuration: 220
    // "none", "wipe-up", "wipe-down", "wipe-left", "wipe-right", "circle", "crossfade-scale"
    property string transitionType: "wipe-left"

    width: iconSize
    height: iconSize

    property var _outlinePaths: []
    property var _filledPaths: []

    property bool _hasOutline: _outlinePaths.length > 0
    property bool _hasFilled: _filledPaths.length > 0
    property real _diagonal: Math.sqrt(root.width * root.width + root.height * root.height)

    property real _progress: {
        if (root._hasOutline && !root._hasFilled) return 0;
        if (!root._hasOutline && root._hasFilled) return 1;
        return filled ? 1 : 0;
    }

    Behavior on _progress {
        enabled: transitionType !== "none"
        NumberAnimation {
            duration: root.transitionDuration
            easing.type: Easing.InOutQuad
        }
    }

    onNameChanged: loadSvgs()
    Component.onCompleted: loadSvgs()

    property bool _needFiles: false
    property bool _outlineLoaded: false
    property bool _filledLoaded: false
    property string _outlineFile: ""
    property string _filledFile: ""
    property var _outlineNext: []
    property var _filledNext: []

    function loadSvgs() {
        if (!name) {
            root._outlinePaths = [];
            root._filledPaths = [];
            root._needFiles = false;
            return;
        }

        const dir = Quickshell.shellDir + "/icons/";
        const n = name.toLowerCase();
        root._outlineFile = dir + "outline/" + n + ".svg";
        root._filledFile = dir + "filled/" + n + ".svg";

        const o = IconCache.get(root._outlineFile);
        const f = IconCache.get(root._filledFile);
        root._outlineLoaded = o !== undefined;
        root._filledLoaded = f !== undefined;
        root._outlineNext = o ?? [];
        root._filledNext = f ?? [];
        root._needFiles = !(root._outlineLoaded && root._filledLoaded);
        root.checkCompletion();
    }

    function checkCompletion() {
        if (root._outlineLoaded && root._filledLoaded) {
            root._outlinePaths = root._outlineNext;
            root._filledPaths = root._filledNext;
            root._needFiles = false;
        }
    }

    Item {
        id: outlineClip
        clip: transitionType !== "circle" && transitionType !== "crossfade-scale" && transitionType !== "none"
        visible: root._hasOutline && root._progress < 1
        
        width: {
            if (transitionType === "circle" || transitionType === "crossfade-scale" || transitionType === "none")
                return root.width;
            let w = root.width;
            if (transitionType === "wipe-left" || transitionType === "wipe-right")
                w = root.width * (1 - root._progress);
            return Math.round(w);
        }
        height: {
            if (transitionType === "circle" || transitionType === "crossfade-scale" || transitionType === "none")
                return root.height;
            let h = root.height;
            if (transitionType === "wipe-up" || transitionType === "wipe-down")
                h = root.height * (1 - root._progress);
            return Math.round(h);
        }
        x: {
            if (transitionType === "circle" || transitionType === "crossfade-scale" || transitionType === "none")
                return 0;
            let val = 0;
            if (transitionType === "wipe-right")
                val = root.width - width;
            return Math.round(val);
        }
        y: {
            if (transitionType === "circle" || transitionType === "crossfade-scale" || transitionType === "none")
                return 0;
            let val = 0;
            if (transitionType === "wipe-down")
                val = root.height - height;
            return Math.round(val);
        }

        opacity: (transitionType === "circle" || transitionType === "crossfade-scale") ? (1 - root._progress) : 1
        scale: transitionType === "crossfade-scale" ? (1.0 - 0.2 * root._progress) : 1.0
        transformOrigin: Item.Center

        Shape {
            id: outlineShape
            property color shapeColor: root.color

            width: root.width
            height: root.height
            x: -outlineClip.x
            y: root.height - outlineClip.y
            antialiasing: true
            preferredRendererType: Shape.CurveRenderer

            Instantiator {
                active: root._hasOutline
                model: root._outlinePaths
                onObjectAdded: (index, object) => outlineShape.data.push(object)
                onObjectRemoved: (index, object) => {
                    let idx = outlineShape.data.indexOf(object);
                    if (idx !== -1) outlineShape.data.splice(idx, 1);
                }

                ShapePath {
                    strokeWidth: 0
                    fillColor: outlineShape.shapeColor
                    scale: Qt.size(outlineShape.width / 960, outlineShape.height / 960)
                    PathSvg { path: modelData }
                }
            }
        }
    }

    Item {
        id: filledClip
        visible: root._hasFilled && root._progress > 0
        
        width: {
            if (transitionType === "circle" || transitionType === "crossfade-scale" || transitionType === "none")
                return root.width;
            let w = root.width;
            if (transitionType === "wipe-left" || transitionType === "wipe-right")
                w = root.width * root._progress;
            return Math.round(w);
        }
        height: {
            if (transitionType === "circle" || transitionType === "crossfade-scale" || transitionType === "none")
                return root.height;
            let h = root.height;
            if (transitionType === "wipe-up" || transitionType === "wipe-down")
                h = root.height * root._progress;
            return Math.round(h);
        }
        x: {
            if (transitionType === "circle" || transitionType === "crossfade-scale" || transitionType === "none")
                return 0;
            let val = 0;
            if (transitionType === "wipe-left")
                val = root.width - width;
            return Math.round(val);
        }
        y: {
            if (transitionType === "circle" || transitionType === "crossfade-scale" || transitionType === "none")
                return 0;
            let val = 0;
            if (transitionType === "wipe-up")
                val = root.height - height;
            return Math.round(val);
        }

        clip: transitionType !== "circle" && transitionType !== "crossfade-scale" && transitionType !== "none"
        
        layer.enabled: transitionType === "circle" && root._progress > 0 && root._progress < 1
        layer.samples: 4
        layer.smooth: true
        layer.effect: MultiEffect {
            maskEnabled: true
            maskSource: circleMaskLoader.item
        }

        opacity: transitionType === "crossfade-scale" ? root._progress : 1
        scale: transitionType === "crossfade-scale" ? (0.8 + 0.2 * root._progress) : 1.0
        transformOrigin: Item.Center

        Shape {
            id: filledShape
            property color shapeColor: root.color

            width: root.width
            height: root.height
            x: -filledClip.x
            y: root.height - filledClip.y
            antialiasing: true
            preferredRendererType: Shape.CurveRenderer

            Instantiator {
                active: root._hasFilled
                model: root._filledPaths
                onObjectAdded: (index, object) => filledShape.data.push(object)
                onObjectRemoved: (index, object) => {
                    let idx = filledShape.data.indexOf(object);
                    if (idx !== -1) filledShape.data.splice(idx, 1);
                }

                ShapePath {
                    strokeWidth: 0
                    fillColor: filledShape.shapeColor
                    scale: Qt.size(filledShape.width / 960, filledShape.height / 960)
                    PathSvg { path: modelData }
                }
            }
        }
    }

    Loader {
        id: circleMaskLoader

        active: root.transitionType === "circle"
        visible: false

        sourceComponent: Item {
            width: root.width
            height: root.height
            layer.enabled: true
            layer.samples: 4
            layer.smooth: true

            Rectangle {
                width: root._diagonal * root._progress
                height: root._diagonal * root._progress
                radius: width / 2
                anchors.centerIn: parent
                color: "black"
            }
        }
    }

    Loader {
        active: root._needFiles

        sourceComponent: Item {
            FileView {
                printErrors: false
                path: root._outlineLoaded ? "" : root._outlineFile
                onLoaded: {
                    const paths = IconCache.set(path, text());
                    if (path === root._outlineFile) {
                        root._outlineNext = paths;
                        root._outlineLoaded = true;
                        root.checkCompletion();
                    }
                }
                onLoadFailed: {
                    const paths = IconCache.set(path, "");
                    if (path === root._outlineFile) {
                        root._outlineNext = paths;
                        root._outlineLoaded = true;
                        root.checkCompletion();
                    }
                }
            }

            FileView {
                printErrors: false
                path: root._filledLoaded ? "" : root._filledFile
                onLoaded: {
                    const paths = IconCache.set(path, text());
                    if (path === root._filledFile) {
                        root._filledNext = paths;
                        root._filledLoaded = true;
                        root.checkCompletion();
                    }
                }
                onLoadFailed: {
                    const paths = IconCache.set(path, "");
                    if (path === root._filledFile) {
                        root._filledNext = paths;
                        root._filledLoaded = true;
                        root.checkCompletion();
                    }
                }
            }
        }
    }
}
