import QtQuick

// A number that follows `target` like a damped spring (the same motion as the
// desktop's island). Integrated against real frame time; keeps its velocity
// when the target changes mid-flight.
QtObject {
    id: spring

    property real target: 0
    property real value: 0
    property real velocity: 0
    property real response: 0.45   // seconds per swing
    property real damping: 0.8     // 1 = no overshoot
    property real epsilon: 0.02
    property real from: NaN

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
        dt = Math.min(dt, 1 / 30);
        const w = 2 * Math.PI / Math.max(0.05, response);
        const k = w * w;
        const c = 2 * damping * w;
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
