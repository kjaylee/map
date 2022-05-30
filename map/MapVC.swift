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
import OpenLocationCode

class MapVC: UIViewController {
    var userCoordinate: CLLocationCoordinate2D? {
        didSet {
            guard let coordinate = userCoordinate else {
                return
            }
            if let plusCode = OpenLocationCode.encode(latitude: coordinate.latitude,
                                                      longitude: coordinate.longitude,
                                                      codeLength: 8) {
                print("Open Location Code: \(plusCode)")
                mapAddPolygon(area: OpenLocationCode.decode(plusCode))
            }
        }
    }
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
    func mapAddPolygon(area: OpenLocationCodeArea?) {
        guard let area = area else {
            return
        }
        let coordinates = [
            CLLocationCoordinate2DMake(area.latitudeLo, area.longitudeLo),
            CLLocationCoordinate2DMake(area.latitudeHi, area.longitudeLo),
            CLLocationCoordinate2DMake(area.latitudeHi, area.longitudeHi),
            CLLocationCoordinate2DMake(area.latitudeLo, area.longitudeHi),
        ]
        mapView.addOverlay(MKPolygon(coordinates: coordinates, count: coordinates.count))
    }
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let overlay = overlay as? MKTileOverlay {
            return MKTileOverlayRenderer(tileOverlay: overlay)
        }
        if let overlay = overlay as? MKPolygon {
            let renderer = MKPolygonRenderer(polygon: overlay)
            renderer.fillColor = UIColor.black.withAlphaComponent(0.1)
            renderer.strokeColor = UIColor.orange
            renderer.lineWidth = 0.5
            return renderer
        }
        return MKOverlayRenderer(overlay: overlay)
    }
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        let coordinate = self.mapView.userLocation.coordinate
        self.userCoordinate = coordinate
        let distance: CLLocationDistance = 3000
        let pitch: CGFloat = 60
        let heading = 120.0
        let camera = MKMapCamera(lookingAtCenter: coordinate, fromDistance: distance, pitch: pitch, heading: heading)
        UIView.animate(withDuration: 1.8, delay: 0, options: [.curveEaseIn, .allowUserInteraction]) { [weak self] in
            self?.mapView.setCamera(camera, animated: true)
        } completion: { [weak self] _ in
            UIView.animate(withDuration: 0.8, delay: 0, options: [.curveEaseOut, .allowUserInteraction]) {
                let heading = 0.0
                let camera = MKMapCamera(lookingAtCenter: coordinate, fromDistance: distance, pitch: pitch, heading: heading)
                self?.mapView.setCamera(camera, animated: true)
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
        CLGeocoder().reverseGeocodeLocation(firstLocation) { [weak self] list, error in
            guard let firstMark = list?.first, let coordinate = firstMark.location?.coordinate else {
                return
            }
            print(firstMark)
            let heading = 0.0
            let distance: CLLocationDistance = 3000
            let pitch: CGFloat = 60
            let camera = MKMapCamera(lookingAtCenter: coordinate, fromDistance: distance, pitch: pitch, heading: heading)
            self?.mapView.setCamera(camera, animated: true)
            self?.userCoordinate = coordinate
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
