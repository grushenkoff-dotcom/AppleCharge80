import SwiftUI

/// Exact geometry reconstructed from the supplied 814×1000 Apple SVG.
/// The body and leaf remain separate so the leaf can grow independently.
struct AppleBodyShape: Shape {
    func path(in rect: CGRect) -> Path {
        let sx = rect.width / 814.0
        let sy = rect.height / 1000.0

        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: x * sx, y: y * sy)
        }

        var path = Path()

        path.move(to: p(788.1, 340.9))

        path.addCurve(
            to: p(679.9, 531.4),
            control1: p(782.3, 345.4),
            control2: p(679.9, 403.1)
        )

        path.addCurve(
            to: p(813.8, 733.6),
            control1: p(679.9, 679.8),
            control2: p(810.0, 730.4)
        )

        path.addCurve(
            to: p(745.1, 875.5),
            control1: p(813.2, 736.8),
            control2: p(793.1, 803.6)
        )

        path.addCurve(
            to: p(589.6, 998.6),
            control1: p(702.3, 937.1),
            control2: p(657.1, 998.6)
        )

        path.addCurve(
            to: p(425.6, 959.1),
            control1: p(522.1, 998.6),
            control2: p(503.6, 959.1)
        )

        path.addCurve(
            to: p(259.7, 999.9),
            control1: p(349.1, 959.1),
            control2: p(321.4, 999.9)
        )

        path.addCurve(
            to: p(104.2, 872.9),
            control1: p(197.5, 999.9),
            control2: p(153.6, 942.9)
        )

        path.addCurve(
            to: p(0, 541.8),
            control1: p(46.7, 790.7),
            control2: p(0, 663.0)
        )

        path.addCurve(
            to: p(250.8, 244.3),
            control1: p(0, 347.4),
            control2: p(126.4, 244.3)
        )

        path.addCurve(
            to: p(413.5, 287.7),
            control1: p(316.9, 244.3),
            control2: p(372.0, 287.7)
        )

        path.addCurve(
            to: p(589.8, 241.7),
            control1: p(453.0, 287.7),
            control2: p(514.6, 241.7)
        )

        path.addCurve(
            to: p(788.1, 340.9),
            control1: p(618.3, 241.7),
            control2: p(760.7, 244.3)
        )

        path.closeSubpath()

        return path
    }
}

struct AppleLeafShape: Shape {
    func path(in rect: CGRect) -> Path {
        let sx = rect.width / 814.0
        let sy = rect.height / 1000.0

        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: x * sx, y: y * sy)
        }

        var path = Path()

        path.move(to: p(554.1, 159.4))

        path.addCurve(
            to: p(607.2, 20.1),
            control1: p(585.2, 122.5),
            control2: p(607.2, 71.3)
        )

        path.addCurve(
            to: p(605.3, 0),
            control1: p(607.2, 13.0),
            control2: p(606.6, 5.8)
        )

        path.addCurve(
            to: p(458.2, 75.8),
            control1: p(554.7, 1.9),
            control2: p(494.5, 33.7)
        )

        path.addCurve(
            to: p(403.1, 211.3),
            control1: p(429.7, 108.2),
            control2: p(403.1, 159.4)
        )

        path.addCurve(
            to: p(405.0, 229.4),
            control1: p(403.1, 219.1),
            control2: p(404.4, 226.9)
        )

        path.addCurve(
            to: p(418.6, 230.7),
            control1: p(408.2, 230.0),
            control2: p(413.4, 230.7)
        )

        path.addCurve(
            to: p(554.1, 159.4),
            control1: p(464.0, 230.7),
            control2: p(521.1, 200.3)
        )

        path.closeSubpath()

        return path
    }
}

struct AppleLogoShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = AppleBodyShape().path(in: rect)
        path.addPath(AppleLeafShape().path(in: rect))
        return path
    }
}

// Compatibility alias for older project references.
typealias LeafShape = AppleLeafShape
