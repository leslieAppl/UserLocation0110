//
//  ViewController.swift
//  UserLocation0110
//
//  Created by leslie on 1/10/20.
//  Copyright © 2020 leslie. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class MapScreen: UIViewController {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var addressLbl: UILabel!
    
    @IBOutlet weak var startBtn: UIButton!
    @IBOutlet weak var goBtn: UIButton!
    
    
    let locationManager = CLLocationManager()
    let REGION_IN_METERS: Double = 10000
    
    var previousLocation: CLLocation?
    var directionsArray: [MKDirections] = []
    
    var startingLocation: CLLocationCoordinate2D?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // MapKit Framework
        mapView.delegate = self
        
        // CoreLocation Framework
        checkLocationServices()
        
        goBtn.isEnabled = false
    }
    
    func checkLocationServices() {
        // check device's setting > private > location services, if it's turned on
        if CLLocationManager.locationServicesEnabled() {
            setupLocationManager()
            checkLocationAuthorization()
        } else {
            // Show alert letting the user know they have to turn this on.
        }
    }
    
    func setupLocationManager() {
        // basic setting
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
//        locationManager.activityType = .fitness
//        locationManager.distanceFilter = 10
        
        // Background Mode Setting...
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.showsBackgroundLocationIndicator = true
        //        locationManager.distanceFilter = kCLDistanceFilterNone // default
        
        // TODO: Also use a timer?
    }
    
    
    func checkLocationAuthorization() {
        // In a switch statement for readablility each function involves no more 5 implementations.
        switch CLLocationManager.authorizationStatus() {
        case .authorizedWhenInUse:
            // Do Map Stuff
            startTrackingUserLocation()
            
        case .denied:
            // Show alert instructing them how to turn on permissions
            break
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .restricted:
            // Show an alert leeting them know what's up
            break
        case .authorizedAlways:
            break
        }
    }
    
    func centerViewOnUserLocation() {
        // var location: CLLocation? { get } 'The most recently retrieved user location.'
        if let location = locationManager.location?.coordinate {
            let region = MKCoordinateRegion.init(center: location, latitudinalMeters: REGION_IN_METERS, longitudinalMeters: REGION_IN_METERS)
            mapView.setRegion(region, animated: true)
            
        }
    }
    
    func startTrackingUserLocation() {
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .follow
//        centerViewOnUserLocation()
        
        // starting firing off locasion manager delegate method - didUpdateLocations:
        locationManager.startUpdatingLocation()
        
        // Map View Center Location
        previousLocation = getCenterLocation(for: mapView)
    }
    
    func getCenterLocation(for mapView: MKMapView) -> CLLocation {
        let latitude = mapView.centerCoordinate.latitude
        let longitude = mapView.centerCoordinate.longitude
        
        return CLLocation(latitude: latitude, longitude: longitude)
    }
    
    func getDirections() {
        // current user location
        guard let location = locationManager.location?.coordinate else {
            //TODO: Inform user we don't have their current location
            return
        }
        
        let request = createDirectionsrequest(from: location)
        let directions = MKDirections(request: request)
        resetMapView(withNew: directions)
        
        directions.calculate { [unowned self](response, error) in
            // TODO: Handle error if needed
            guard let response = response else { return } //TODO: Show respnse not available in an alert
            for route in response.routes {
                self.mapView.addOverlay(route.polyline)
                
            }
        }
    }
    
    func createDirectionsrequest(from coordinate: CLLocationCoordinate2D) -> MKDirections.Request {
        let destinationCoordinate = getCenterLocation(for: mapView).coordinate
        let startingLocation = MKPlacemark(coordinate: self.startingLocation!)
        let destination = MKPlacemark(coordinate: destinationCoordinate)
        
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: startingLocation)
        request.destination = MKMapItem(placemark: destination)
        request.transportType = .walking
//        request.transportType = .automobile
//        request.transportType = .transit
        
        request.requestsAlternateRoutes = true
        
        return request
    }
    
    func resetMapView(withNew dirctions: MKDirections) {
        mapView.removeOverlays(mapView.overlays)
        directionsArray.append(dirctions)
        let _ = directionsArray.map { $0.cancel() }
        directionsArray.removeAll()
    }
    
    @IBAction func goBtnPressed(_ sender: Any) {
        getDirections()
    }
    
    @IBAction func startBtnPressed(_ sender: Any) {
        self.startingLocation = getCenterLocation(for: mapView).coordinate
        goBtn.isEnabled = true
    }
    
}

extension MapScreen: CLLocationManagerDelegate {
    
    // starting fired by locationManager.startUpdatingLocation()
//    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
//        // check if there are any CLLocations
//        guard let location = locations.last else { return }
//        let center = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
//        let region = MKCoordinateRegion.init(center: center, latitudinalMeters: REGION_IN_METERS, longitudinalMeters: REGION_IN_METERS)
//        mapView.setRegion(region, animated: true)
//    }
    
    // delegate whenever the authorization has been changed
    // if been changed, it will auto check in the checkLocationAuthorization() function,
    // so that the user don't need to choose the permition options manually every time the app popped up.
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        checkLocationAuthorization()
    }
}

extension MapScreen: MKMapViewDelegate {
    // track the center of map when region did change
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        let center = getCenterLocation(for: mapView)
        let geoCoder = CLGeocoder()
        
        // guard make sure if 'previousLocation' has the value
        guard let previousLocation = self.previousLocation else { return }
        guard center.distance(from: previousLocation) > 50 else { return }
        self.previousLocation = center
        
        geoCoder.cancelGeocode()
        
        // can't call the GeoCoder all the time, otherwise it will failed
        geoCoder.reverseGeocodeLocation(center) { [weak self](placemarks, error) in
            guard let self = self else { return }
            
            if let _ = error {
                // TODO: Show alert informing the user
                return
            }
            
            guard let placemark = placemarks?.first else {
                // TODO: Show alert informing the user
                return
            }
            
            let streetNumber = placemark.subThoroughfare ?? ""
            let streetName = placemark.thoroughfare ?? ""
            print(streetNumber)
            print(streetName)
            
            // If your app has a long running task, such as making network call, run it on a global system queue, or on another background dispatch queue. Alternatively, use asynchronous versions of the call, if available.
            DispatchQueue.main.async {
                self.addressLbl.text = "\(streetNumber) \(streetName)"
            }
        }
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay as! MKPolyline)
        renderer.strokeColor = .blue
        renderer.lineWidth = 3
        
        return renderer
    }
}
