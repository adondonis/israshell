import QtQuick
import qs.style
import qs.services

Item {
    id: visualizer

    property bool pause: false
    property bool useMock: false
    property real mockTime: 0
    property real overrideMaxHeight: -1

    property var style: Config.cava
    property var values: useMock ? mockValues : CavaService.values
    property real maxValue: 100
    property var mockValues: []

    function resolveColor(opt, fallback) {
        if (opt.indexOf("#") === 0 || opt.indexOf("rgb") === 0)
            return opt;
        if (typeof Colors !== "undefined" && Colors.md3 && Colors.md3[opt])
            return Colors.md3[opt];
        return fallback;
    }

    property color cavaColor: resolveColor(visualizer.style.color || "primary", "#3b82f6")
    property color cavaColorAlt: resolveColor(visualizer.style.colorAlt || "error", "#ef4444")

    function localRearrange(fakeSweep, layout) {
        if (!fakeSweep || fakeSweep.length < 2) return fakeSweep;
        let right = fakeSweep;
        let left = fakeSweep.slice().reverse();

        if (layout === "edges") {
            let leftMirrored = left.slice().reverse();
            let rightMirrored = right.slice().reverse();
            return leftMirrored.concat(rightMirrored);
        }
        if (layout === "mono") {
            let leftAligned = left.slice().reverse();
            let combined = [];
            for (let i = 0; i < right.length; i++) {
                combined.push((leftAligned[i] + right[i]) / 2);
            }
            return combined;
        }
        return left.concat(right);
    }

    Timer {
        interval: 26
        running: visualizer.useMock && visualizer.visible && !visualizer.pause
        repeat: true
        onTriggered: {
            visualizer.mockTime += 0.05;
            const numBars = visualizer.style.bars || 30;
            const t = visualizer.mockTime;
            const fake = [];
            for (let i = 0; i < numBars; i++) {
                const wave1 = Math.sin(i * 0.3 + t * 2.0) * 25;
                const wave2 = Math.cos(i * 0.15 - t * 1.2) * 20;
                const wave3 = Math.sin(i * 0.05 + t * 0.5) * 15;
                const heightVal = Math.max(5, 35 + wave1 + wave2 + wave3);
                const envelope = i < numBars * 0.2
                    ? 0.4 + 0.6 * (i / (numBars * 0.2))
                    : 1.0 - 0.7 * ((i - numBars * 0.2) / (numBars * 0.8));
                fake.push(Math.round(heightVal * envelope));
            }
            visualizer.mockValues = visualizer.localRearrange(fake, visualizer.style.layout);
        }
    }

    ShaderEffect {
        id: fx
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: visualizer.style.position === 1 ? undefined : parent.top
        anchors.bottom: visualizer.style.position === 1 ? parent.bottom : undefined
        height: Math.min(parent.height, maxHeight + 4)
        visible: visualizer.style.enabled || visualizer.useMock
        fragmentShader: Qt.resolvedUrl("../shaders/cava.frag.qsb")

        property real n: 0
        property real maxHeight: visualizer.overrideMaxHeight > 0 ? visualizer.overrideMaxHeight : visualizer.style.heightPct / 100 * visualizer.height
        property real alpha: visualizer.style.opacity
        property real fromBottom: visualizer.style.position === 1 ? 1 : 0
        property real renderType: ["curve", "bars", "blocks"].indexOf(visualizer.style.renderType)
        property real smoothCurve: visualizer.style.curveType === "smooth" ? 1 : 0
        property real drawFill: visualizer.style.drawFill ? 1 : 0
        property real drawStroke: visualizer.style.drawStroke ? 1 : 0
        property real colorStyle: ["solid", "loudness", "gradient-v", "gradient-h"].indexOf(visualizer.style.colorStyle)
        property real loudness: 0
        property real peak: 0
        property vector2d res: Qt.vector2d(width, height)
        property vector4d colBase: Qt.vector4d(visualizer.cavaColor.r, visualizer.cavaColor.g, visualizer.cavaColor.b, 1)
        property vector4d colAlt: Qt.vector4d(visualizer.cavaColorAlt.r, visualizer.cavaColorAlt.g, visualizer.cavaColorAlt.b, 1)
        property vector4d v0
        property vector4d v1
        property vector4d v2
        property vector4d v3
        property vector4d v4
        property vector4d v5
        property vector4d v6
        property vector4d v7
        property vector4d v8
        property vector4d v9
        property vector4d v10
        property vector4d v11
        property vector4d v12
        property vector4d v13
        property vector4d v14
        property vector4d v15
        property vector4d v16
        property vector4d v17
        property vector4d v18
        property vector4d v19
        property vector4d v20
        property vector4d v21
        property vector4d v22
        property vector4d v23
        property vector4d v24
        property vector4d v25

        function pack(vals) {
            const len = Math.min(vals ? vals.length : 0, 104);
            const inv = 1 / visualizer.maxValue;
            let sum = 0, mx = 0;
            for (let k = 0; k < 26; k++) {
                const j = k * 4;
                const a = j < len ? vals[j] : 0, b = j + 1 < len ? vals[j + 1] : 0;
                const c = j + 2 < len ? vals[j + 2] : 0, d = j + 3 < len ? vals[j + 3] : 0;
                sum += a + b + c + d;
                mx = Math.max(mx, a, b, c, d);
                fx["v" + k] = Qt.vector4d(a * inv, b * inv, c * inv, d * inv);
            }
            n = len;
            peak = mx * inv;
            loudness = len > 0 ? Math.min(1, sum * inv / len * 2) : 0;
        }

        Connections {
            target: visualizer
            enabled: !visualizer.pause
            function onValuesChanged() { fx.pack(visualizer.values); }
            function onMaxValueChanged() { fx.pack(visualizer.values); }
            function onPauseChanged() { fx.pack(visualizer.values); }
        }
        Component.onCompleted: pack(visualizer.values)
    }
}
