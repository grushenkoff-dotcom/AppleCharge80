import SwiftUI

// MARK: - Exact Apple logo geometry
//
// Геометрия взята непосредственно из исходного apple-logo.svg:
// 814 × 1000.
// Первый subpath = тело Apple.
// Второй subpath = лист.
//
// Никакой собственной перерисовки силуэта здесь нет.

struct AppleLogoShape: Shape {

    func path(in rect: CGRect) -> Path {
        AppleLogoGeometry.bodyPath(in: rect)
            .appending(AppleLogoGeometry.leafPath(in: rect))
    }
}

// MARK: - Body only

struct AppleBodyShape: Shape {

    func path(in rect: CGRect) -> Path {
        AppleLogoGeometry.bodyPath(in: rect)
    }
}

// MARK: - Leaf only

struct AppleLeafShape: Shape {

    func path(in rect: CGRect) -> Path {
        AppleLogoGeometry.leafPath(in: rect)
    }
}

// MARK: - Exact SVG geometry

private enum AppleLogoGeometry {

    static func bodyPath(in rect: CGRect) -> Path {

        let sx = rect.width / 814.0
        let sy = rect.height / 1000.0

        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(
                x: rect.minX + x * sx,
                y: rect.minY + y * sy
            )
        }

        var path = Path()

        // Original SVG body:
        //
        // M788.1 340.9
        // c-5.8 4.5-108.2 62.2-108.2 190.5
        // c0 148.4 130.3 200.9 134.2 202.2
        // c-.6 3.2-20.7 71.9-68.7 141.9
        // c-42.8 61.6-87.5 123.1-155.5 123.1
        // s-85.5-39.5-164-39.5
        // c-76.5 0-103.7 40.8-165.9 40.8
        // s-105.6-57-155.5-127
        // C46.7 790.7 0 663 0 541.8
        // c0-194.4 126.4-297.5 250.8-297.5
        // c66.1 0 121.2 43.4 162.7 43.4
        // c39.5 0 101.1-46 176.3-46
        // c28.5 0 130.9 2.6 198.3 99.2
        // z

        path.move(to: p(788.1, 340.9))

        path.addCurve(
            to: p(679.9, 531.4),
            control1: p(782.3, 345.4),
            control2: p(679.9, 403.1)
        )

        path.addCurve(
            to: p(813.3, 733.6),
            control1: p(679.9, 679.8),
            control2: p(810.0, 730.3)
        )

        path.addCurve(
            to: p(744.6, 875.5),
            control1: p(812.7, 736.8),
            control2: p(791.3, 803.6)
        )

        path.addCurve(
            to: p(589.1, 998.6),
            control1: p(701.8, 937.1),
            control2: p(656.6, 998.6)
        )

        path.addCurve(
            to: p(425.1, 959.1),
            control1: p(503.6, 998.6),
            control2: p(468.0, 959.1)
        )

        path.addCurve(
            to: p(259.2, 999.9),
            control1: p(348.3, 959.1),
            control2: p(321.4, 999.9)
        )

        path.addCurve(
            to: p(103.7, 872.9),
            control1: p(41.7, 942.9),
            control2: p(0.0, 815.9)
        )

        path.addCurve(
            to: p(0.0, 541.8),
            control1: p(46.7, 790.7),
            control2: p(0.0, 663.0)
        )

        path.addCurve(
            to: p(250.8, 244.3),
            control1: p(0.0, 347.4),
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
            control1: p(618.3, 244.3),
            control2: p(720.7, 243.0)
        )

        path.closeSubpath()

        return path
    }

    static func leafPath(in rect: CGRect) -> Path {

        let sx = rect.width / 814.0
        let sy = rect.height / 1000.0

        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(
                x: rect.minX + x * sx,
                y: rect.minY + y * sy
            )
        }

        var path = Path()

        // Exact second SVG subpath.
        // It starts at 554.1 / 159.4.

        path.move(to: p(554.1, 159.4))

        path.addCurve(
            to: p(607.2, 20.1),
            control1: p(585.2, 122.5),
            control2: p(607.2, 71.3)
        )

        path.addCurve(
            to: p(605.3, 0.0),
            control1: p(606.6, 5.8),
            control2: p(606.0, -0.0)
        )

        path.addCurve(
            to: p(458.2, 75.8),
            control1: p(554.7, 1.9),
            control2: p(494.5, 33.7)
        )

        path.addCurve(
            to: p(403.1, 211.3),
            control1: p(429.6, 108.2),
            control2: p(403.1, 159.4)
        )

        path.addCurve(
            to: p(405.0, 229.4),
            control1: p(403.7, 219.1),
            control2: p(404.4, 227.5)
        )

        path.addCurve(
            to: p(418.6, 230.7),
            control1: p(408.2, 230.7),
            control2: p(413.4, 231.3)
        )

        path.addCurve(
            to: p(554.1, 159.4),
            control1: p(520.1, 200.3),
            control2: p(577.1, 169.9)
        )

        path.closeSubpath()

        return path
    }
}

// MARK: - Compatibility names

typealias LeafShape = AppleLeafShape
