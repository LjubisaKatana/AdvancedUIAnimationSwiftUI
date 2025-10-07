//
//  CompassView.swift
//  AdvancedUIAnimationSwiftUI
//
//  Created by Ljubisa Katana on 7.10.25..
//

import SwiftUI

// MARK: - Theme
private extension Color {
    static let militaryGreenDeep = Color(red: 0.07, green: 0.12, blue: 0.08)
    static let militaryGreen = Color(red: 0.12, green: 0.22, blue: 0.14)
    static let radarNeon = Color(red: 0.60, green: 1.00, blue: 0.60)
}

// MARK: - Compass View
struct CompassView: View {
    @State private var autoRotationDegrees: Double = 0
    @State private var isAutoRotating: Bool = true
    @GestureState private var dragRotationDelta: Double = 0

    private let ringGradient = AngularGradient(
        gradient: Gradient(colors: [Color.radarNeon.opacity(0.9), Color.radarNeon.opacity(0.2), Color.radarNeon.opacity(0.9)]),
        center: .center
    )

    var body: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height)
            ZStack {
                // Background
                RadialGradient(
                    colors: [.militaryGreenDeep, .militaryGreen],
                    center: .center,
                    startRadius: 2,
                    endRadius: size
                )
                .ignoresSafeArea()

                // Rotating dial (bezel + ticks + labels)
                ZStack {
                    Circle()
                        .strokeBorder(lineWidth: size * 0.02)
                        .foregroundStyle(ringGradient)
                        .shadow(color: Color.radarNeon.opacity(0.6), radius: size * 0.03)

                    TicksView()
                        .stroke(style: .init(lineWidth: 2, lineCap: .round))
                        .foregroundStyle(Color.radarNeon.opacity(0.85))

                    CardinalLabels()
                        .foregroundStyle(Color.radarNeon)
                        .font(.system(size: size * 0.1, weight: .semibold, design: .rounded))
                        .shadow(color: Color.radarNeon.opacity(0.6), radius: size * 0.02)
                }
                .padding(size * 0.08)
                .rotationEffect(.degrees(autoRotationDegrees + dragRotationDelta))
                .contentShape(Circle())
                .gesture(rotationDragGesture(size: size))
                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: dragRotationDelta)

                // Fixed needle with glow (two compact arrows from center ring)
                NeedleView(centerDiameter: size * 0.09)
                    .frame(width: size * 0.04, height: size * 0.48)
                    .shadow(color: Color.radarNeon.opacity(0.4), radius: size * 0.02)

                // Center cap (solid black to hide arrow edges)
                Circle()
                    .fill(.black)
                    .frame(width: size * 0.09, height: size * 0.09)
                    .overlay(
                        Circle()
                            .stroke(Color.radarNeon.opacity(0.9), lineWidth: 2)
                    )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .deviceTilt3D()
        }
        .background(Color.militaryGreenDeep)
        .onAppear {
            startAutoRotation()
        }
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.6)) {
                isAutoRotating.toggle()
            }
            if isAutoRotating { startAutoRotation() }
        }
        .overlay(alignment: .bottom) {
            VStack(spacing: 8) {
                Text(isAutoRotating ? "Auto Rotating" : "Drag to rotate • Tap to resume")
                    .font(.footnote)
                    .foregroundStyle(Color.radarNeon.opacity(0.9))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.black.opacity(0.25), in: Capsule())
            }
            .padding(.bottom, 24)
        }
        .accessibilityLabel("Animated compass")
    }

    private func startAutoRotation() {
        guard isAutoRotating else { return }
        autoRotationDegrees = 0
        withAnimation(.linear(duration: 12).repeatForever(autoreverses: false)) {
            autoRotationDegrees = 360
        }
    }

    // MARK: Gesture
    private func rotationDragGesture(size: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .updating($dragRotationDelta) { value, state, _ in
                let vector = CGVector(dx: value.location.x - size / 2, dy: value.location.y - size / 2)
                let angle = atan2(vector.dy, vector.dx) - .pi / 2
                let startVector = CGVector(dx: value.startLocation.x - size / 2, dy: value.startLocation.y - size / 2)
                let startAngle = atan2(startVector.dy, startVector.dx) - .pi / 2
                state = Double((angle - startAngle)) * 180 / .pi
            }
            .onChanged { _ in
                if isAutoRotating { isAutoRotating = false }
            }
    }
}

// MARK: - Components
private struct TicksView: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2

        for i in 0..<360 {
            guard i % 2 == 0 else { continue } // every 2° for smoothness
            let isMajor = i % 30 == 0
            let isMedium = i % 10 == 0

            let tickLength: CGFloat = isMajor ? radius * 0.12 : (isMedium ? radius * 0.08 : radius * 0.04)
            let angle = CGFloat(i) * .pi / 180

            let outer = CGPoint(
                x: center.x + cos(angle) * (radius - 4),
                y: center.y + sin(angle) * (radius - 4)
            )
            let inner = CGPoint(
                x: center.x + cos(angle) * (radius - tickLength),
                y: center.y + sin(angle) * (radius - tickLength)
            )
            path.move(to: inner)
            path.addLine(to: outer)
        }
        return path
    }
}

private struct CardinalLabels: View {
    var body: some View {
        ZStack {
            LabelAt(angle: 0, text: "N")
            LabelAt(angle: 90, text: "E")
            LabelAt(angle: 180, text: "S")
            LabelAt(angle: 270, text: "W")
        }
    }

    private struct LabelAt: View {
        let angle: Double
        let text: String

        var body: some View {
            GeometryReader { proxy in
                let radius = min(proxy.size.width, proxy.size.height) / 2
                Text(text)
                    .kerning(1)
                    .position(
                        x: proxy.size.width / 2 + cos(CGFloat(angle) * .pi / 180) * (radius * 0.78),
                        y: proxy.size.height / 2 + sin(CGFloat(angle) * .pi / 180) * (radius * 0.78)
                    )
            }
        }
    }
}

private struct NeedleView: View {
    let centerDiameter: CGFloat

    var body: some View {
        GeometryReader { proxy in
            let totalHeight = proxy.size.height
            let innerGap = centerDiameter * 0.60 // keep arrows clearly outside center ring
            let arrowLength = (totalHeight - innerGap) / 2

            VStack(spacing: innerGap) {
                // North arrow (lighter green)
                Arrow()
                    .fill(Color.radarNeon.opacity(0.95))
                    .frame(height: arrowLength)
                    .overlay(Arrow().stroke(Color.white.opacity(0.35), lineWidth: 0.5))

                // South arrow (darker green)
                Arrow()
                    .fill(Color.radarNeon.opacity(0.6))
                    .frame(height: arrowLength)
                    .rotationEffect(.degrees(180))
                    .overlay(Arrow().stroke(Color.white.opacity(0.25), lineWidth: 0.5).rotationEffect(.degrees(180)))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

// Slender arrow shape with a short base
private struct Arrow: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        // Simple isosceles triangle wedge
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Motion
// MotionManager moved to its own file.

// Simple isosceles triangle pointing up by default
private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

#Preview("Compass") {
    CompassView()
}


