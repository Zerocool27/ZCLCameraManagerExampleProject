//
//  CameraViewController+Location.swift
//  WhatsAround
//
//  Created by fatih on 3/12/19.
//  Copyright © 2019 turquaz. All rights reserved.
//
import CoreLocation

extension ShotViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        userLocation = locations[0]
        
        let horAcc = userLocation.horizontalAccuracy // double, in meter
        let verAcc = userLocation.verticalAccuracy // double, in meter
        let speed  = userLocation.speed // double, in meter/sec
        let course = userLocation.course // double in degrees relative to true north
        
        if course >= 0 {
            gps.course = course
        }
        
        if speed >= 0 {
            gps.speed = speed
        }
        
        if horAcc >= 0 {
            gps.horizontalAccuracy = horAcc
        }
        
        if verAcc >= 0 {
            gps.verticalAccuracy = verAcc
        }
        TempStore.sharedInstance.userLocation = locations[0]
        TempStore.sharedInstance.gps = gps
        TempStore.sharedInstance.currentLocation.lat = locations.last!.coordinate.latitude
        TempStore.sharedInstance.currentLocation.lon = locations.last!.coordinate.longitude
        
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse {
            // authorized location status when app is in use; update current location
            locationManager.startUpdatingLocation()
            // implement additional logic if needed...
        } else if status == .denied || status == .notDetermined || status == .restricted {
            super.showAlert(message: "Location Service is not available", title: "Error", type: .error)
        }
    }
    
}
