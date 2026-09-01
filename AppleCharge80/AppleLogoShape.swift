import SwiftUI

struct AppleLogoShape: Shape {
    func path(in rect: CGRect) -> Path {
        transformedPath(includeLeaf: true, rect: rect)
    }
}

struct AppleBodyShape: Shape {
    func path(in rect: CGRect) -> Path {
        transformedPath(includeLeaf: false, rect: rect)
    }
}

struct AppleLeafShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()

        p.move(to: CGPoint(x: 554.1, y: 159.4))
        p.addCurve(
            to: CGPoint(x: 607.2, y: 20.1),
            control1: CGPoint(x: 585.2, y: 122.5),
            control2: CGPoint(x: 607.2, y: 71.3)
        )
        p.addCurve(
            to: CGPoint(x: 605.3, y: 0.0),
            control1: CGPoint(x: 607.2, y: 13.0),
            control2: CGPoint(x: 613.2, y: 5.8)
        )
        p.addCurve(
            to: CGPoint(x: 458.2, y: 75.8),
            control1: CGPoint(x: 554.7, y: 1.9),
            control2: CGPoint(x: 494.5, y: 33.7)
        )
        p.addCurve(
            to: CGPoint(x: 403.1, y: 211.3),
            control1: CGPoint(x: 429.7, y: 108.2),
            control2: CGPoint(x: 403.1, y: 159.4)
        )
        p.addCurve(
            to: CGPoint(x: 405.0, y: 229.4),
            control1: CGPoint(x: 403.1, y: 219.1),
            control2: CGPoint(x: 404.4, y: 226.9)
        )
        p.addCurve(
            to: CGPoint(x: 418.6, y: 230.7),
            control1: CGPoint(x: 408.2, y: 235.4),
            control2: CGPoint(x: 413.4, y: 230.7)
        )
        p.addCurve(
            to: CGPoint(x: 554.1, y: 159.4),
            control1: CGPoint(x: 464.0, y: 230.7),
            control2: CGPoint(x: 521.1, y: 200.3)
        )
        p.closeSubpath()

        return fit(p, in: rect)
    }
}

private func transformedPath(includeLeaf: Bool, rect: CGRect) -> Path {
    var p = Path()

    // Apple body from the supplied 814 × 1000 SVG.
    p.move(to: CGPoint(x: 788.1, y: 340.9))
    p.addCurve(to: CGPoint(x: 679.9, y: 531.4),
               control1: CGPoint(x: 782.3, y: 345.4),
               control2: CGPoint(x: 679.9, y: 403.1))
    p.addCurve(to: CGPoint(x: 814.1, y: 733.6),
               control1: CGPoint(x: 679.9, y: 679.8),
               control2: CGPoint(x: 810.2, y: 732.3))
    p.addCurve(to: CGPoint(x: 745.4, y: 875.5),
               control1: CGPoint(x: 820.1, y: 736.8),
               control2: CGPoint(x: 793.4, y: 805.5))
    p.addCurve(to: CGPoint(x: 589.9, y: 998.6),
               control1: CGPoint(x: 702.6, y: 937.1),
               control2: CGPoint(x: 657.9, y: 998.6))
    p.addCurve(to: CGPoint(x: 425.9, y: 959.1),
               control1: CGPoint(x: 521.9, y: 998.6),
               control2: CGPoint(x: 504.4, y: 959.1))
    p.addCurve(to: CGPoint(x: 260.0, y: 999.9),
               control1: CGPoint(x: 349.4, y: 959.1),
               control2: CGPoint(x: 322.2, y: 999.9))
    p.addCurve(to: CGPoint(x: 104.5, y: 872.9),
               control1: CGPoint(x: 197.8, y: 999.9),
               control2: CGPoint(x: 154.4, y: 942.9))
    p.addCurve(to: CGPoint(x: 0.0, y: 541.8),
               control1: CGPoint(x: 46.7, y: 790.7),
               control2: CGPoint(x: 0.0, y: 663.0))
    p.addCurve(to: CGPoint(x: 250.8, y: 244.3),
               control1: CGPoint(x: 0.0, y: 347.4),
               control2: CGPoint(x: 126.4, y: 244.3))
    p.addCurve(to: CGPoint(x: 413.5, y: 287.7),
               control1: CGPoint(x: 316.9, y: 244.3),
               control2: CGPoint(x: 372.0, y: 287.7))
    p.addCurve(to: CGPoint(x: 589.8, y: 241.7),
               control1: CGPoint(x: 453.0, y: 287.7),
               control2: CGPoint(x: 514.6, y: 241.7))
    p.addCurve(to: CGPoint(x: 788.1, y: 340.9),
               control1: CGPoint(x: 618.3, y: 241.7),
               control2: CGPoint(x: 720.7, y: 244.3))
    p.closeSubpath()

    if includeLeaf {
        p.move(to: CGPoint(x: 554.1, y: 159.4))
        p.addCurve(to: CGPoint(x: 607.2, y: 20.1),
                   control1: CGPoint(x: 585.2, y: 122.5),
                   control2: CGPoint(x: 607.2, y: 71.3))
        p.addCurve(to: CGPoint(x: 605.3, y: 0.0),
                   control1: CGPoint(x: 607.2, y: 13.0),
                   control2: CGPoint(x: 613.2, y: 5.8))
        p.addCurve(to: CGPoint(x: 458.2, y: 75.8),
                   control1: CGPoint(x: 554.7, y: 1.9),
                   control2: CGPoint(x: 494.5, y: 33.7))
        p.addCurve(to: CGPoint(x: 403.1, y: 211.3),
                   control1: CGPoint(x: 429.7, y: 108.2),
                   control2: CGPoint(x: 403.1, y: 159.4))
        p.addCurve(to: CGPoint(x: 405.0, y: 229.4),
                   control1: CGPoint(x: 403.1, y: 219.1),
                   control2: CGPoint(x: 404.4, y: 226.9))
        p.addCurve(to: CGPoint(x: 418.6, y: 230.7),
                   control1: CGPoint(x: 408.2, y: 235.4),
                   control2: CGPoint(x: 413.4, y: 230.7))
        p.addCurve(to: CGPoint(x: 554.1, y: 159.4),
                   control1: CGPoint(x: 464.0, y: 230.7),
                   control2: CGPoint(x: 521.1, y: 200.3))
        p.closeSubpath()
    }

    return fit(p, in: rect)
}

private func fit(_ source: Path, in rect: CGRect) -> Path {
    var transform = CGAffineTransform(
        translationX: rect.minX,
        y: rect.minY
    )

    let sx = rect.width / 814.0
    let sy = rect.height / 1000.0

    transform = transform.scaledBy(x: sx, y: sy)

    return source.applying(transform)
}
