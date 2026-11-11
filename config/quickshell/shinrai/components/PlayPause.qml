import QtQuick
import QtQuick.Window
import qs.config

// ▶ that folds into ❚❚ and back. Each icon is drawn as two four-cornered
// shapes; the corners slide from one icon's spots to the other's.
Item {
    id: root

    property bool playing: false   // true shows pause
    property color color: Theme.ink
    property real m: playing ? 1 : 0

    Behavior on m {
        NumberAnimation { duration: 240; easing.type: Easing.OutCubic }
    }

    implicitWidth: 18
    implicitHeight: 18

    // corners in a unit box: [play shape, pause shape] for each half
    readonly property var halves: [
        [[[0.25, 0.11], [0.57, 0.305], [0.57, 0.695], [0.25, 0.89]],
         [[0.21, 0.13], [0.41, 0.13], [0.41, 0.87], [0.21, 0.87]]],
        [[[0.57, 0.305], [0.89, 0.5], [0.89, 0.5], [0.57, 0.695]],
         [[0.59, 0.13], [0.79, 0.13], [0.79, 0.87], [0.59, 0.87]]]
    ]

    onMChanged: canvas.requestPaint()
    onColorChanged: canvas.requestPaint()

    // Drawn at the screen's real pixel density, then scaled back, so it stays
    // sharp at scale 2.
    Canvas {
        id: canvas

        readonly property real dpr: Math.max(1, Screen.devicePixelRatio)

        width: root.width * dpr
        height: root.height * dpr
        scale: 1 / dpr
        transformOrigin: Item.TopLeft
        antialiasing: true

        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()

        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            const s = Math.min(width, height);
            const ox = (width - s) / 2;
            const oy = (height - s) / 2;
            const k = root.m;
            const c = root.color;
            const css = "rgba(" + Math.round(c.r * 255) + "," + Math.round(c.g * 255) + ","
                      + Math.round(c.b * 255) + "," + c.a + ")";

            ctx.fillStyle = css;
            ctx.strokeStyle = css;
            ctx.lineJoin = "round";
            ctx.lineWidth = s * 0.07;   // rounds the corners a little

            for (const half of root.halves) {
                const a = half[0];
                const b = half[1];
                ctx.beginPath();
                for (let i = 0; i < 4; i++) {
                    const x = ox + s * (a[i][0] + (b[i][0] - a[i][0]) * k);
                    const y = oy + s * (a[i][1] + (b[i][1] - a[i][1]) * k);
                    if (i === 0) ctx.moveTo(x, y);
                    else ctx.lineTo(x, y);
                }
                ctx.closePath();
                ctx.fill();
                ctx.stroke();
            }
        }
    }
}
