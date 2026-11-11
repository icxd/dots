import QtQuick
import QtQuick.Effects
import qs.config

// Soft shadow under the island once it has grown, so it stands off the
// windows below. Loaded separately (IslandWindow's Loader) because
// RectangularShadow needs Qt 6.9; with an older Qt only the shadow is missing.
RectangularShadow {
    anchors.fill: parent
    radius: Math.min(height / 2, Theme.radius)
    blur: 34
    spread: -2
    offset: Qt.vector2d(0, 10)
    color: Qt.rgba(0, 0, 0, 0.45)
}
