//
//  MapVC.swift
//  map
//
//  Created by DEV on 2022/05/27.
//

import UIKit
import SwiftUI
import SnapKit
import MapKit
import GoogleMapsTileOverlay
import CoreLocation

class MapVC: UIViewController {
    lazy var mapView: MKMapView = {
        let mapView = MKMapView()
        if let jsonURL = Bundle.main.url(forResource: "MapStyle", withExtension: "json"),
           let tileOverlay = try? GoogleMapsTileOverlay(jsonURL: jsonURL) {
            tileOverlay.canReplaceMapContent = true
            mapView.addOverlay(tileOverlay, level: .aboveRoads)
        }
        mapView.showsUserLocation = true
        mapView.delegate = self
        return mapView
    }()
    lazy var locationManager: CLLocationManager = {
        let locationManager = CLLocationManager()
        locationManager.delegate = self
        return locationManager
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(mapView)
        mapView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        initializedLocation()
    }
}

extension MapVC: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let tileOverlay = overlay as? MKTileOverlay {
            return MKTileOverlayRenderer(tileOverlay: tileOverlay)
        }
        return MKOverlayRenderer(overlay: overlay)
    }
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        let coordinate = self.mapView.userLocation.coordinate
        let distance: CLLocationDistance = 3000
        let pitch: CGFloat = 60
        let heading = 120.0
        let camera = MKMapCamera(lookingAtCenter: coordinate, fromDistance: distance, pitch: pitch, heading: heading)
        UIView.animate(withDuration: 1.8, delay: 0, options: [.curveEaseIn, .allowUserInteraction]) {
            self.mapView.setCamera(camera, animated: true)
        } completion: { _ in
            UIView.animate(withDuration: 0.8, delay: 0, options: [.curveEaseOut, .allowUserInteraction]) {
                let heading = 0.0
                let camera = MKMapCamera(lookingAtCenter: coordinate, fromDistance: distance, pitch: pitch, heading: heading)
                self.mapView.setCamera(camera, animated: true)
            }
        }

    }
}

extension MapVC: CLLocationManagerDelegate {
    func initializedLocation() {
        let authorizationStatus: CLAuthorizationStatus
        if #available(iOS 14, *) {
            authorizationStatus = locationManager.authorizationStatus
        } else {
            authorizationStatus = CLLocationManager.authorizationStatus()
        }
        switch authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .restricted,.denied:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorizedWhenInUse:
            locationManager.requestLocation()
        @unknown default:
            break
        }
    }
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        guard status == .authorizedWhenInUse else {
            return
        }
        manager.requestLocation()
    }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let firstLocation = locations.first else {
          return
        }
        CLGeocoder().reverseGeocodeLocation(firstLocation) { list, error in
            guard let firstMark = list?.first, let coordinate = firstMark.location?.coordinate else {
                return
            }
            print(firstMark)
            let heading = 0.0
            let distance: CLLocationDistance = 3000
            let pitch: CGFloat = 60
            let camera = MKMapCamera(lookingAtCenter: coordinate, fromDistance: distance, pitch: pitch, heading: heading)
            self.mapView.setCamera(camera, animated: true)
        }
    }
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error.localizedDescription)
    }
}

struct MapView: UIViewControllerRepresentable {
    typealias UIViewControllerType = MapVC
    
    func makeUIViewController(context: Context) -> MapVC {
        MapVC()
    }

    func updateUIViewController(_ uiViewController: MapVC, context: Context) {
        
    }
}
