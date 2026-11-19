//
//  WravelMark.swift
//  wravel
//

import SwiftUI

/// The wravel W ("Fold"): a flat ribbon folded into a W, its four faces alternating
/// full and half opacity so the fold reads in any tint. Same geometry as the app icon
/// and wravel-android's launcher foreground. Draw it 2:1 (width:height).
struct WravelMark: View {
    var body: some View {
        ZStack {
            FoldFace(index: 0).fill(.primary.opacity(0.5))
            FoldFace(index: 1).fill(.primary)
            FoldFace(index: 2).fill(.primary.opacity(0.5))
            FoldFace(index: 3).fill(.primary)
        }
        .aspectRatio(2, contentMode: .fit)
        .accessibilityElement()
        .accessibilityLabel("wravel")
    }

    /// One face of the fold, back to front, in a 54 x 27 unit box.
    private struct FoldFace: Shape {
        let index: Int

        private static let faces: [[CGPoint]] = [
            [CGPoint(x: 33.75, y: 27), CGPoint(x: 42.75, y: 27), CGPoint(x: 54, y: 0), CGPoint(x: 45, y: 0)],
            [CGPoint(x: 22.5, y: 0), CGPoint(x: 31.5, y: 0), CGPoint(x: 42.75, y: 27), CGPoint(x: 33.75, y: 27)],
            [CGPoint(x: 11.25, y: 27), CGPoint(x: 20.25, y: 27), CGPoint(x: 31.5, y: 0), CGPoint(x: 22.5, y: 0)],
            [CGPoint(x: 0, y: 0), CGPoint(x: 9, y: 0), CGPoint(x: 20.25, y: 27), CGPoint(x: 11.25, y: 27)],
        ]

        func path(in rect: CGRect) -> Path {
            let scale = rect.width / 54
            var path = Path()
            let points = Self.faces[index].map {
                CGPoint(x: rect.minX + $0.x * scale, y: rect.minY + $0.y * scale)
            }
            path.addLines(points)
            path.closeSubpath()
            return path
        }
    }
}

#Preview {
    VStack(spacing: 24) {
        WravelMark().frame(width: 72)
        WravelMark().frame(width: 72).foregroundStyle(.blue)
    }
    .padding()
}
