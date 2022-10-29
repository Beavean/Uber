//
//  HomeController.swift
//  Uber
// 
//  Created by Beavean on 13.10.2022.
//

import UIKit
import Firebase
import MapKit

private let reuseIdentifier = "LocationCell"
private let annotationIdentifier = "DriverAnnotation"

private enum ActionButtonConfiguration {
    case showMenu
    case dismissActionView
    
    init() {
        self = .showMenu
    }
}

final class HomeController: UIViewController {
    
    //MARK: - Properties
    
    private final let locationInputViewHeight: CGFloat = 200
    private final let rideActionViewHeight: CGFloat = 300
    private var actionButtonConfig = ActionButtonConfiguration()
    private let rideActionView = RideActionView()
    private var route: MKRoute?
    private let mapView = MKMapView()
    private let locationManager = LocationHandler.shared.locationManager
    private let inputActivationView = LocationInputActivationView()
    private let locationInputView = LocationInputView()
    private let tableView = UITableView()
    
    private var searchResults = [MKPlacemark]() {
        didSet { self.tableView.reloadData() }
    }
    
    private var user: User? {
        didSet {
            locationInputView.user = user
            if user?.accountType == .passenger {
                fetchDrivers()
                configureLocationInputActivationView()
                observeCurrentTrip()
            } else {
                observeTrips()
            }
        }
    }
    
    private var trip: Trip? {
        didSet {
            guard let user else { return }
            if user.accountType == .driver {
                guard let trip else { return }
                let controller = PickupController(trip: trip)
                controller.modalPresentationStyle = .fullScreen
                controller.delegate = self
                self.present(controller, animated: true)
            } else {
                print("DEBUG: Show ride action view for accepted trip")
            }
        }
    }
    
    private lazy var actionButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "line.3.horizontal"), for: .normal)
        button.tintColor = .black
        button.addTarget(self, action: #selector(actionButtonPressed), for: .touchUpInside)
        return button
    }()
    
    //MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        checkIfUserIsLoggedIn()
        enableLocationServices()
        //        signOut()
    }
    
    
    
    //MARK: - Selectors
    
    @objc private func actionButtonPressed() {
        switch actionButtonConfig {
        case .showMenu:
            print("DEBUG: Show menu")
        case .dismissActionView:
            removeAnnotationsAndOverlays()
            mapView.showAnnotations(mapView.annotations, animated: true)
            UIView.animate(withDuration: 0.3) {
                self.inputActivationView.alpha = 1
                self.configureActionButton(config: .showMenu)
                self.animateRideActionView(shouldShow: false)
            }
        }
    }
    
    //MARK: - API
    
    private func observeCurrentTrip() {
        Service.shared.observeCurrentTrip { [weak self] trip in
            self?.trip = trip
            guard let driverUid = trip.driverUid, let state = trip.state else { return }
            switch state {
            case .requested:
                break
            case .accepted:
                self?.shouldPresentLoadingView(false)
                self?.removeAnnotationsAndOverlays()
                self?.zoomForActiveTrip(withDriverUid: driverUid)
                Service.shared.fetchUserData(uid: driverUid) { driver in
                    self?.animateRideActionView(shouldShow: true, config: .tripAccepted, user: driver)
                }
            case .driverArrived:
                self?.rideActionView.config = .driverArrived
            case .inProgress:
                break
            case .completed:
                break
            }
        }
    }
    
    func startTrip() {
        guard let trip = self.trip else { return }
        Service.shared.updateTripState(trip: trip, state: .inProgress) { [weak self] error, reference in
            if let error {
                self?.showAlert(title: "Error starting trip", error: error)
            }
            self?.rideActionView.config = .tripInProgress
            self?.removeAnnotationsAndOverlays()
            self?.mapView.addAnnotationAndSelect(forCoordinate: trip.destinationCoordinates)
            let placemark = MKPlacemark(coordinate: trip.destinationCoordinates)
            let mapItem = MKMapItem(placemark: placemark)
            self?.generatePolyline(toDestination: mapItem)
        }
    }
    
    private func fetchUserData() {
        guard let currentUid = Auth.auth().currentUser?.uid else { return  }
        Service.shared.fetchUserData(uid: currentUid) { [weak self] user in
            self?.user = user
        }
    }
    
    private func fetchDrivers() {
        guard let location = locationManager?.location else { return }
        Service.shared.fetchDrivers(location: location) { [weak self] driver in
            guard let coordinate = driver.location?.coordinate else { return }
            let annotation = DriverAnnotation(uid: driver.uid, coordinate: coordinate)
            print("DEBUG: Driver coordinate is  \(coordinate)")
            var driverIsVisible: Bool {
                return self?.mapView.annotations.contains { annotation in
                    guard let driverAnnotation = annotation as? DriverAnnotation else { return false }
                    if driverAnnotation.uid == driver.uid {
                        driverAnnotation.updateAnnotationPosition(withCoordinate: coordinate)
                        self?.zoomForActiveTrip(withDriverUid: driver.uid)
                        return true
                    }
                    return false
                } ?? false
            }
            if !driverIsVisible {
                self?.mapView.addAnnotation(annotation)
            }
        }
    }
    
    private func observeTrips() {
        Service.shared.observeTrips { [weak self] trip in
            self?.trip = trip
        }
    }
    
    private func checkIfUserIsLoggedIn() {
        if let _ = Auth.auth().currentUser?.uid {
            configure()
        } else {
            DispatchQueue.main.async {
                let nav = UINavigationController(rootViewController: LoginController())
                nav.modalPresentationStyle = .fullScreen
                self.present(nav, animated: true)
            }
        }
    }
    
    private func signOut() {
        do {
            try Auth.auth().signOut()
        } catch {
            self.showAlert(error: error)
        }
    }
    
    //MARK: - Helpers
    
    func configure() {
        configureUI()
        fetchUserData()
    }
    
    private func configureActionButton(config: ActionButtonConfiguration) {
        switch config {
        case .showMenu:
            self.actionButton.setImage(UIImage(systemName: "line.3.horizontal"), for: .normal)
            self.actionButtonConfig = .showMenu
        case .dismissActionView:
            actionButton.setImage(UIImage(systemName: "arrow.left"), for: .normal)
            actionButtonConfig = .dismissActionView
        }
    }
    
    private func configureUI() {
        configureMapView()
        configureRideActionView()
        view.addSubview(actionButton)
        actionButton.anchor(top: view.safeAreaLayoutGuide.topAnchor, left: view.leftAnchor, paddingTop: 16, paddingLeft: 16, width: 30, height: 30)
        configureTableView()
    }
    
    private func configureLocationInputActivationView() {
        view.addSubview(inputActivationView)
        inputActivationView.centerX(inView: view)
        inputActivationView.setDimensions(height: 50, width: view.frame.width - 64)
        inputActivationView.anchor(top: actionButton.bottomAnchor, paddingTop: 24)
        inputActivationView.alpha = 0
        inputActivationView.delegate = self
        UIView.animate(withDuration: 1) {
            self.inputActivationView.alpha = 1
        }
    }
    
    private func configureMapView() {
        view.addSubview(mapView)
        mapView.frame = view.frame
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .follow
        mapView.delegate = self
    }
    
    private func configureLocationInputView() {
        locationInputView.delegate = self
        view.addSubview(locationInputView)
        locationInputView.anchor(top: view.topAnchor, left: view.leftAnchor, right: view.rightAnchor, height: 200)
        locationInputView.alpha = 0
        UIView.animate(withDuration: 0.15) {
            self.locationInputView.alpha = 1
        } completion: { _ in
            UIView.animate(withDuration: 0.3) {
                self.tableView.frame.origin.y = self.locationInputViewHeight
            }
        }
    }
    
    private func configureRideActionView() {
        view.addSubview(rideActionView)
        rideActionView.delegate = self
        rideActionView.frame = CGRect(x: 0, y: view.frame.height, width: view.frame.width, height: rideActionViewHeight)
    }
    
    private func configureTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.keyboardDismissMode = .onDrag
        tableView.register(LocationCell.self, forCellReuseIdentifier: reuseIdentifier)
        tableView.rowHeight = 60
        tableView.tableFooterView = UIView()
        let height = view.frame.height - locationInputViewHeight
        tableView.frame = CGRect(x: 0, y: view.frame.height, width: view.frame.width, height: height)
        view.addSubview(tableView)
    }
    
    private func dismissLocationView(completion: ((Bool) -> Void)? = nil) {
        UIView.animate(withDuration: 0.3, animations: {
            self.locationInputView.alpha = 0
            self.tableView.frame.origin.y = self.view.frame.height
            self.locationInputView.removeFromSuperview()
        }, completion: completion)
    }
    
    private func animateRideActionView(shouldShow: Bool, destination: MKPlacemark? = nil, config: RideActionViewConfiguration? = nil, user: User? = nil) {
        let yOrigin = shouldShow ? self.view.frame.height - self.rideActionViewHeight : self.view.frame.height
        UIView.animate(withDuration: 0.3) {
            self.rideActionView.frame.origin.y = yOrigin
        }
        if shouldShow {
            guard let config else { return }
            if let destination {
                rideActionView.destination = destination
            }
            if let user {
                rideActionView.user = user
            }
            rideActionView.config = config
        }
    }
}

//MARK: - MapView Helper functions

private extension HomeController {
    private func searchBy(naturalLanguageQuery: String, completion: @escaping([MKPlacemark]) -> Void) {
        var results = [MKPlacemark]()
        let request = MKLocalSearch.Request()
        request.region = mapView.region
        request.naturalLanguageQuery = naturalLanguageQuery
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            if let error {
                self.showAlert(title: "Error receiving search results", error: error)
            }
            guard let response else { return }
            response.mapItems.forEach { item in
                results.append(item.placemark)
            }
            completion(results)
        }
    }
    
    private func generatePolyline(toDestination destination: MKMapItem) {
        let request = MKDirections.Request()
        request.source = MKMapItem.forCurrentLocation()
        request.destination = destination
        request.transportType = .automobile
        let directionRequest = MKDirections(request: request)
        directionRequest.calculate { [weak self] response, error in
            if let error {
                self?.showAlert(title: "Error calculating route", error: error)
            }
            guard let response else { return }
            self?.route = response.routes.first
            guard let polyline = self?.route?.polyline else { return }
            self?.mapView.addOverlay(polyline)
        }
    }
    
    private func removeAnnotationsAndOverlays() {
        mapView.annotations.forEach { annotation in
            if let annotation = annotation as? MKPointAnnotation {
                mapView.removeAnnotation(annotation)
            }
        }
        if mapView.overlays.count > 0 {
            mapView.removeOverlay(mapView.overlays[0])
        }
    }
    
    private func centerMapOnUserLocation() {
        guard let coordinate = locationManager?.location?.coordinate else { return }
        let region = MKCoordinateRegion(center: coordinate, latitudinalMeters: 2000, longitudinalMeters: 200)
        mapView.setRegion(region, animated: true)
    }
    
    private func setCustomRegion(withCoordinates coordinates: CLLocationCoordinate2D) {
        let region = CLCircularRegion(center: coordinates, radius: 10000, identifier: "pickup")
        locationManager?.startMonitoring(for: region)
        print("DEBUG: Did set region")
    }
    
    func zoomForActiveTrip(withDriverUid uid: String) {
        var annotations = [MKAnnotation]()
        self.mapView.annotations.forEach { annotation in
            if let annotation = annotation as? DriverAnnotation {
                if annotation.uid == uid {
                    annotations.append(annotation)
                }
            }
            if let userAnnotation = annotation as? MKUserLocation {
                annotations.append(userAnnotation)
            }
        }
        self.mapView.zoomToFit(annotations: annotations)
    }
}

//MARK: - MKMapViewDelegate

extension HomeController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        guard let user = self.user, user.accountType == .driver, let location = userLocation.location else { return }
        Service.shared.updateDriverLocation(location: location)
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if let annotation = annotation as? DriverAnnotation {
            let view = MKAnnotationView(annotation: annotation, reuseIdentifier: annotationIdentifier)
            view.image = UIImage(systemName: "car.fill")
            return view
        }
        return nil
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let route = self.route {
            let polyline = route.polyline
            let lineRenderer = MKPolylineRenderer(overlay: polyline)
            lineRenderer.strokeColor = .mainBlueTint
            lineRenderer.lineWidth = 4
            return lineRenderer
        }
        return MKOverlayRenderer()
    }
}

//MARK: - CLLocationManagerDelegate

extension HomeController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
        print("DEBUG: Did start monitoring for region \(region)")
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        guard let trip = self.trip else { return }
        Service.shared.updateTripState(trip: trip, state: .driverArrived) { [weak self] error, reference in
            self?.rideActionView.config = .pickupPassenger
            if let error {
                self?.showAlert(title: "Error", error: error)
            }
        }
    }
    
    private func enableLocationServices() {
        locationManager?.delegate = self
        switch locationManager?.authorizationStatus {
        case .authorizedAlways:
            print("DEBUG: Authorised always")
            locationManager?.startUpdatingLocation()
            locationManager?.desiredAccuracy = kCLLocationAccuracyBest
        case .authorizedWhenInUse:
            print("DEBUG: Authorised when in use")
            locationManager?.requestAlwaysAuthorization()
        case .denied:
            break
        case .notDetermined:
            locationManager?.requestWhenInUseAuthorization()
            print("DEBUG: Not determined")
        case .restricted:
            break
        case .none:
            break
        @unknown default:
            break
        }
    }
}

//MARK: - LocationInputActivationViewDelegate

extension HomeController: LocationInputActivationViewDelegate {
    func presentLocationInputView() {
        inputActivationView.alpha = 0
        configureLocationInputView()
    }
}

//MARK: - LocationInputViewDelegate

extension HomeController: LocationInputViewDelegate {
    func executeSearch(query: String) {
        searchBy(naturalLanguageQuery: query) { [weak self] placemarks in
            self?.searchResults = placemarks
        }
    }
    
    func dismissLocationInputView() {
        dismissLocationView { [weak self] _ in
            UIView.animate(withDuration: 0.5, animations: {
                self?.inputActivationView.alpha = 1
            })
        }
    }
}

//MARK: - UITableViewDataSource/Delegate

extension HomeController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return section == 0 ? "Favourite" : "Nearest"
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? 2 : searchResults.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) as? LocationCell else { return UITableViewCell() }
        if indexPath.section == 1 {
            cell.placemark = searchResults[indexPath.row]
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedPlacemark = searchResults[indexPath.row]
        configureActionButton(config: .dismissActionView)
        let destination = MKMapItem(placemark: selectedPlacemark)
        generatePolyline(toDestination: destination)
        dismissLocationView { [weak self] _ in
            self?.mapView.addAnnotationAndSelect(forCoordinate: selectedPlacemark.coordinate)
            guard let annotations = self?.mapView.annotations.filter({ !$0.isKind(of: DriverAnnotation.self) }) else { return }
            self?.mapView.zoomToFit(annotations: annotations)
            self?.animateRideActionView(shouldShow: true, destination: selectedPlacemark, config: .requestRide)
        }
    }
}

//MARK: - RideActionViewDelegate

extension HomeController: RideActionViewDelegate {
    func uploadTrip(_ view: RideActionView) {
        guard let pickupCoordinates = locationManager?.location?.coordinate,
              let destinationCoordinates = view.destination?.coordinate else { return }
        shouldPresentLoadingView(true, message: "Finding you a ride...")
        Service.shared.uploadTrip(pickupCoordinates, destinationCoordinates) { [weak self] error, reference in
            if let error {
                self?.showAlert(title: "Failed to upload trip", error: error)
                return
            }
            UIView.animate(withDuration: 0.3) {
                guard let hideHeight = self?.view.frame.height else { return }
                self?.rideActionView.frame.origin.y = hideHeight
            }
        }
    }
    
    func cancelTrip() {
        Service.shared.cancelTrip { [weak self] error, reference in
            if let error {
                self?.showAlert(title: "Failed to cancel trip", error: error)
                return
            }
            self?.centerMapOnUserLocation()
            self?.animateRideActionView(shouldShow: false)
            self?.removeAnnotationsAndOverlays()
            self?.actionButton.setImage(UIImage(systemName: "line.3.horizontal"), for: .normal)
            self?.actionButtonConfig = .showMenu
            self?.inputActivationView.alpha = 1
        }
    }
    
    func pickupPassenger() {
        startTrip()
    }
}

//MARK: - PickupControllerDelegate

extension HomeController: PickupControllerDelegate {
    func didAcceptTrip(_ trip: Trip) {
        self.trip = trip
        self.mapView.addAnnotationAndSelect(forCoordinate: trip.pickupCoordinates)
        setCustomRegion(withCoordinates: trip.pickupCoordinates)
        let placemark = MKPlacemark(coordinate: trip.pickupCoordinates)
        let mapItem = MKMapItem(placemark: placemark)
        generatePolyline(toDestination: mapItem)
        mapView.zoomToFit(annotations: mapView.annotations)
        Service.shared.observeTripCancelled(trip: trip) {
            self.removeAnnotationsAndOverlays()
            self.animateRideActionView(shouldShow: false)
            self.centerMapOnUserLocation()
            self.showMessage("The trip has been cancelled.", withTitle: "Sorry")
        }
        self.dismiss(animated: true) {
            Service.shared.fetchUserData(uid: trip.passengerUid) { passenger in
                self.animateRideActionView(shouldShow: true, config: .tripAccepted, user: passenger)
            }
        }
    }
}
