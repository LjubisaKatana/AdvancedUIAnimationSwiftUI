//
//  MotionManager.swift
//  AdvancedUIAnimationSwiftUI
//
//  Created by Assistant on 7.10.25.
//

import Foundation
import CoreMotion
import SwiftUI

final class MotionManager: ObservableObject {
    private let manager = CMMotionManager()
    private let queue = OperationQueue()

    @Published var pitchDegrees: Double = 0
    @Published var rollDegrees: Double = 0

    var isAvailable: Bool { manager.isDeviceMotionAvailable }

    func start() {
        guard manager.isDeviceMotionAvailable else { return }
        manager.deviceMotionUpdateInterval = 1.0 / 50.0
        manager.startDeviceMotionUpdates(using: .xArbitraryZVertical, to: queue) { [weak self] motion, _ in
            guard let self, let m = motion else { return }
            let pitch = m.attitude.pitch * 180 / .pi
            let roll = m.attitude.roll * 180 / .pi
            let clampedPitch = pitch.clamped(to: -22...22)
            let clampedRoll = roll.clamped(to: -22...22)
            DispatchQueue.main.async {
                withAnimation(.easeOut(duration: 0.12)) {
                    self.pitchDegrees = clampedPitch
                    self.rollDegrees = clampedRoll
                }
            }
        }
    }

    func stop() {
        manager.stopDeviceMotionUpdates()
    }
}

extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        min(max(self, limits.lowerBound), limits.upperBound)
    }
}


