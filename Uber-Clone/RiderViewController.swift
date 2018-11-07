//
//  RiderViewController.swift
//  Uber-Clone
//
//  Created by K.K. on 3.11.18.
//  Copyright © 2018 K.K. All rights reserved.
//

import UIKit
import MapKit
import FirebaseAuth
import FirebaseDatabase

class RiderViewController: UIViewController, CLLocationManagerDelegate {
    
    // Outlets
    @IBOutlet weak var map: MKMapView!
    @IBOutlet weak var callDriver: UIButton!
    
    // variables
    var locationManager = CLLocationManager()
    var riderLocation = CLLocationCoordinate2D()
    var driverLocation = CLLocationCoordinate2D()
    var driverCalled = false
    var driverAccepted = false
    var dbRef : DatabaseReference!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        dbRef = Database.database().reference()

        // Do any additional setup after loading the view.
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        if let email = Auth.auth().currentUser?.email {
            dbRef.child("RideRequests").queryOrdered(byChild: "email").queryEqual(toValue: email).observe(.childAdded, with: { (snapshot) in
                self.driverCalled = true
                self.callDriver.setTitle("Cancel Uber", for: .normal)
                self.dbRef.child("RideRequests").removeAllObservers()
                
                if let rideRequestDictionary = snapshot.value as? [String:AnyObject] {
                    if let driverLat = rideRequestDictionary["driverLat"] as? Double {
                        if let driverLon = rideRequestDictionary["driverLon"] as? Double {
                            self.driverLocation = CLLocationCoordinate2D(latitude: driverLat, longitude: driverLon)
                            
                            self.driverAccepted = true
                            self.displayDriverAndRider()
                            
                            if let email = Auth.auth().currentUser?.email{ self.dbRef.child("RideRequests").queryOrdered(byChild: "email").queryEqual(toValue: email).observe(.childChanged, with: { (snapshot) in
                                    if let rideRequestDictionary = snapshot.value as? [String:AnyObject] {
                                        if let driverLat = rideRequestDictionary["driverLat"] as? Double {
                                            if let driverLon = rideRequestDictionary["driverLon"] as? Double {
                                                self.driverLocation = CLLocationCoordinate2D(latitude: driverLat, longitude: driverLon)
                                                self.driverAccepted = true
                                                self.displayDriverAndRider()
                                            }
                                        }
                                    }
                                })
                            }
                        }
                    }
                }
            })
        }
    }
    
    func displayDriverAndRider() {
        let driverCLLocation = CLLocation(latitude: driverLocation.latitude, longitude: driverLocation.longitude)
        let riderCLLocation = CLLocation(latitude: riderLocation.latitude, longitude: riderLocation.longitude)
        let distance = driverCLLocation.distance(from: riderCLLocation) / 1000
        let roundedDistance = round(distance * 100) / 100
        callDriver.setTitle("Your driver is \(roundedDistance)km away!", for: .normal)
        map.removeAnnotations(map.annotations)
        
        let latDelta = abs(driverLocation.latitude - riderLocation.latitude) * 2 + 0.005
        let lonDelta = abs(driverLocation.longitude - riderLocation.longitude) * 2 + 0.005
        
        let region = MKCoordinateRegion(center: riderLocation, span: MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta))
        map.setRegion(region, animated: true)
        
        let riderAnno = MKPointAnnotation()
        riderAnno.coordinate = riderLocation
        riderAnno.title = "Your Location"
        map.addAnnotation(riderAnno)
        
        let driverAnno = MKPointAnnotation()
        driverAnno.coordinate = driverLocation
        driverAnno.title = "Your Driver"
        map.addAnnotation(driverAnno)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let coord = manager.location?.coordinate {
            let center = CLLocationCoordinate2D(latitude: coord.latitude, longitude: coord.longitude)
            riderLocation = center
            
            if driverCalled {
                displayDriverAndRider()
            } else {
                let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
                map.setRegion(region, animated: true)
                // do not pile lots of bubbles there
                map.removeAnnotations(map.annotations)
                // just one bubble
                let annotation = MKPointAnnotation()
                annotation.coordinate = center
                annotation.title = "Your Location"
                map.addAnnotation(annotation)
            }            
        }
    }
    
    @IBAction func callUberPressed(_ sender: Any) {
        if let email = Auth.auth().currentUser?.email {
            if driverCalled {
                driverCalled = false
                callDriver.setTitle("Call an Uber", for: .normal)
                
                dbRef.child("RideRequests").queryOrdered(byChild: "email").queryEqual(toValue: email).observe(.childAdded, with: { (snapshot) in
                    snapshot.ref.removeValue()
                    Database.database().reference().child("RideRequests").removeAllObservers()
                })
            } else {  // driver call not yet placed
                driverCalled = true
                callDriver.setTitle("Cancel Uber", for: .normal)
                
                let rideRequestDictionary : [String:Any] = ["email":email,"lat":riderLocation.latitude,"lon":riderLocation.longitude]
                dbRef.child("RideRequests").childByAutoId().setValue(rideRequestDictionary)
            }
        }
    }
    
    @IBAction func LogOutPressed(_ sender: Any) {
        try? Auth.auth().signOut()
        debugPrint("Log Out success")
        navigationController?.dismiss(animated: true, completion: nil)
    }
}
