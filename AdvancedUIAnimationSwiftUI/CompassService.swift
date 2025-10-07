//
//  CompassService.swift
//  AdvancedUIAnimationSwiftUI
//
//  Streams device heading using CoreLocation.
//

import Foundation
import CoreLocation
import Combine

final class CompassService: NSObject, ObservableObject {
    private let manager = CLLocationManager()
    private var cancellables: Set<AnyCancellable> = []

    @Published var headingDegrees: Double = 0
    @Published var isAvailable: Bool = false
    @Published var accuracy: CLLocationDirectionAccuracy = -1

    override init() {
        super.init()
        manager.delegate = self
    }

    func start() {
        if CLLocationManager.headingAvailable() {
            isAvailable = true
            if manager.authorizationStatus == .notDetermined { manager.requestWhenInUseAuthorization() }
            manager.startUpdatingHeading()
        } else {
            isAvailable = false
        }
    }

    func stop() {
        manager.stopUpdatingHeading()
    }
}

extension CompassService: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedAlways || status == .authorizedWhenInUse {
            if CLLocationManager.headingAvailable() { manager.startUpdatingHeading() }
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        // Prefer true heading when available, otherwise magnetic
        let raw = newHeading.trueHeading > 0 ? newHeading.trueHeading : newHeading.magneticHeading
        accuracy = newHeading.headingAccuracy
        // Light smoothing
        let alpha = 0.15
        headingDegrees = headingDegrees + alpha * (raw - headingDegrees)
    }

    func locationManagerShouldDisplayHeadingCalibration(_ manager: CLLocationManager) -> Bool {
        // Allow system calibration UI if accuracy is poor
        return accuracy < 0 || accuracy > 10
    }
}


