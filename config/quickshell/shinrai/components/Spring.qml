import QtQuick

// A number that follows `target` like a damped spring — the motion behind
// every change of the island's shape.
//
//   response  about how long one swing takes, in seconds (smaller = snappier)
//   damping   1 = settles without overshooting, lower = a little bounce
//
// It's integrated against the real time between frames, so it moves the same
// at 60 or 144 Hz and on a slow software renderer, and it keeps its velocity
// when the target changes mid-flight instead of starting over.
QtObject {
    id: spring

    property real target: 0
    property real value: 0
    property real velocity: 0
    property real response: 0.45
    property real damping: 0.8
    property real epsilon: 0.02     // close enough to stop
    property real from: NaN         // start here instead of at the target
    readonly property bool moving: driver.running

    // Jump to the target without animating.
    function snap() {
        driver.running = false;
        velocity = 0;
        value = target;
    }

    function kick() {
        if (!driver.running) driver.running = true;
    }

    onTargetChanged: kick()

    Component.onCompleted: {
        value = isNaN(from) ? target : from;
        if (value !== target) kick();
    }

    property FrameAnimation driver: FrameAnimation {
        onTriggered: spring.step(frameTime)
    }

    function step(dt) {
        if (!(dt > 0)) return;
        dt = Math.min(dt, 1 / 30);   // after a hitch, slow down rather than jump

        const w = 2 * Math.PI / Math.max(0.05, response);
        const k = w * w;
        const c = 2 * damping * w;

        // small fixed sub-steps keep it stable at any frame rate
        const n = Math.ceil(dt * 240);
        const h = dt / n;
        let x = value;
        let v = velocity;
        for (let i = 0; i < n; i++) {
            v += (k * (target - x) - c * v) * h;
            x += v * h;
        }

        if (Math.abs(target - x) < epsilon && Math.abs(v) < epsilon * 10) {
            driver.running = false;
            velocity = 0;
            value = target;
        } else {
            velocity = v;
            value = x;
        }
    }
}
