import CoreLocation
import Foundation

struct LocationInfo {
    let countryCode: String
    let latitude: Double
    let longitude: Double
}

enum LocationServiceError: LocalizedError {
    case locationDisabled
    case authorizationDenied
    case locationUnavailable

    var errorDescription: String? {
        switch self {
        case .locationDisabled:
            return "Location services are disabled."
        case .authorizationDenied:
            return "Location permission is denied."
        case .locationUnavailable:
            return "Unable to get the current location."
        }
    }
}

final class LocationService: NSObject {
    static let shared = LocationService()

    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    private var completion: ((Result<LocationInfo, LocationServiceError>) -> Void)?

    private override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    func requestLocationInfo(completion: @escaping (Result<LocationInfo, LocationServiceError>) -> Void) {
        guard CLLocationManager.locationServicesEnabled() else {
            completion(.failure(.locationDisabled))
            return
        }

        self.completion = completion

        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorizedWhenInUse:
            locationManager.requestLocation()
        case .denied, .restricted:
            finish(.failure(.authorizationDenied))
        @unknown default:
            finish(.failure(.authorizationDenied))
        }
    }

    private func resolveLocation(_ location: CLLocation) {
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, _ in
            let countryCode = placemarks?.first?.isoCountryCode ?? ""
            let info = LocationInfo(
                countryCode: countryCode,
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude
            )
            self?.finish(.success(info))
        }
    }

    private func finish(_ result: Result<LocationInfo, LocationServiceError>) {
        completion?(result)
        completion = nil
    }
}

extension LocationService: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            manager.requestLocation()
        case .denied, .restricted:
            finish(.failure(.authorizationDenied))
        case .notDetermined:
            break
        @unknown default:
            finish(.failure(.authorizationDenied))
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            finish(.failure(.locationUnavailable))
            return
        }

        resolveLocation(location)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        finish(.failure(.locationUnavailable))
    }
}
