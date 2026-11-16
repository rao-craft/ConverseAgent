extension Template {
    static let stroke = #"""
import SwiftUI

/// A hand-painted stroke over a phrase: a closed shape whose top and bottom edges wave a little, tilt a little and
/// pinch at the tips. Its seed fixes its shape, so a stroke keeps it across redraws and differs from its neighbours.
struct ConverseStroke: Shape {
    var seed: Int

    func path(in rect: CGRect) -> Path {
        var random = ConverseSeededRandom(seed: seed)
        let height = Double(rect.height)
        let tilt = random.next(in: -{{n:stroke.tilt}}...{{n:stroke.tilt}})
        // Three points an edge: left, middle, right.
        let step = Double(rect.width) / 2
        let xs = [Double(rect.minX), Double(rect.minX) + step, Double(rect.minX) + step * 2]
        var top: [CGPoint] = []
        var bottom: [CGPoint] = []
        for (step, x) in xs.enumerated() {
            let lean = tilt * (Double(step) / 2 - 0.5)
            let rise = random.next(in: ({{n:stroke.top#0}} * height)...({{n:stroke.top#1}} * height))
            top.append(CGPoint(x: x, y: Double(rect.minY) + lean + rise))
        }
        for (step, x) in xs.enumerated() {
            let lean = tilt * (Double(step) / 2 - 0.5)
            let fall = random.next(in: ({{n:stroke.bottom#0}} * height)...({{n:stroke.bottom#1}} * height))
            bottom.append(CGPoint(x: x, y: Double(rect.maxY) + lean + fall))
        }
        // The tips pinch: the left more than the right.
        top[0].y += {{n:stroke.pinch#0}} * height
        bottom[0].y -= {{n:stroke.pinch#0}} * height
        top[2].y += {{n:stroke.pinch#1}} * height
        bottom[2].y -= {{n:stroke.pinch#1}} * height

        var path = Path()
        path.move(to: top[0])
        for index in 1..<top.count {
            let from = top[index - 1]
            path.addQuadCurve(to: top[index], control: CGPoint(x: (from.x + top[index].x) / 2, y: from.y))
        }
        let back = Array(bottom.reversed())
        path.addLine(to: back[0])
        for index in 1..<back.count {
            let from = back[index - 1]
            path.addQuadCurve(to: back[index], control: CGPoint(x: (from.x + back[index].x) / 2, y: from.y))
        }
        path.closeSubpath()
        return path
    }
}

/// A small generator of numbers that come out the same for the same seed (SplitMix64).
struct ConverseSeededRandom {
    private var state: UInt64

    init(seed: Int) {
        state = UInt64(bitPattern: Int64(seed &+ 0x9E37_79B9_7F4A_7C1))
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var mixed = state
        mixed = (mixed ^ (mixed >> 30)) &* 0xBF58_476D_1CE4_E5B9
        mixed = (mixed ^ (mixed >> 27)) &* 0x94D0_49BB_1331_11EB
        return mixed ^ (mixed >> 31)
    }

    /// A number in `range`.
    mutating func next(in range: ClosedRange<Double>) -> Double {
        range.lowerBound + Double(next()) / Double(UInt64.max) * (range.upperBound - range.lowerBound)
    }
}

#Preview {
    ConverseStroke(seed: 7)
        .fill(Color.green.opacity({{n:stroke.opacity}}))
        .frame(width: 220, height: 30)
}
"""#

    static let flowLayout = #"""
import SwiftUI

/// Words laid out as text wraps: left to right at their own widths, a new row when the next would not fit, rows a
/// fixed gap apart and each word centred in its row's height. So every word's frame is known, and a stroke can be drawn
/// over a phrase.
struct ConverseFlowLayout: Layout {
    var rowSpacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = arrange(width: proposal.width ?? .infinity, subviews: subviews)
        let height = rows.last.map { $0.top + $0.height } ?? 0
        let widest = rows.map(\.width).max() ?? 0
        return CGSize(width: proposal.width ?? widest, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        for row in arrange(width: bounds.width, subviews: subviews) {
            for item in row.items {
                let y = bounds.minY + row.top + (row.height - item.size.height) / 2
                subviews[item.index].place(at: CGPoint(x: bounds.minX + item.x, y: y), anchor: .topLeading, proposal: ProposedViewSize(item.size))
            }
        }
    }

    private struct Item {
        let index: Int
        let x: CGFloat
        let size: CGSize
    }

    private struct Row {
        var items: [Item] = []
        var top: CGFloat = 0
        var width: CGFloat = 0
        var height: CGFloat = 0
    }

    private func arrange(width: CGFloat, subviews: Subviews) -> [Row] {
        var rows: [Row] = []
        var row = Row()
        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            if !row.items.isEmpty, row.width + size.width > width {
                rows.append(row)
                row = Row(top: row.top + row.height + rowSpacing)
            }
            row.items.append(Item(index: index, x: row.width, size: size))
            row.width += size.width
            row.height = max(row.height, size.height)
        }
        if !row.items.isEmpty { rows.append(row) }
        return rows
    }
}

#Preview {
    ConverseFlowLayout(rowSpacing: {{n:stroke.rows}}) {
        ForEach("words laid out one by one, wrapping as text does".split(separator: " ").map(String.init), id: \.self) { word in
            Text(word + " ")
        }
    }
    .frame(width: 200)
    .padding()
}
"""#
}
