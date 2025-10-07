//
//  View+DeviceTilt3D.swift
//  AdvancedUIAnimationSwiftUI
//
//  Created by Assistant on 7.10.25.
//

import SwiftUI

struct DeviceTilt3DModifier: ViewModifier {
    @StateObject private var motion = MotionManager()
    @GestureState private var tiltDrag: CGSize = .zero

    func body(content: Content) -> some View {
        content
            .rotation3DEffect(.degrees(currentPitchDegrees), axis: (x: 1, y: 0, z: 0), perspective: 0.6)
            .rotation3DEffect(.degrees(currentRollDegrees), axis: (x: 0, y: 1, z: 0), perspective: 0.6)
            .gesture(DragGesture(minimumDistance: 0).updating($tiltDrag) { value, state, _ in
                state = value.translation
            })
            .onAppear { motion.start() }
            .onDisappear { motion.stop() }
    }

    private var currentPitchDegrees: Double {
        if motion.isAvailable { return motion.pitchDegrees }
        return Double(-tiltDrag.height / 4).clamped(to: -18...18)
    }

    private var currentRollDegrees: Double {
        if motion.isAvailable { return motion.rollDegrees }
        return Double(tiltDrag.width / 4).clamped(to: -18...18)
    }
}

extension View {
    func deviceTilt3D() -> some View { modifier(DeviceTilt3DModifier()) }
}


