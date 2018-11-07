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
    var appDB : DatabaseReference!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        appDB = Database.database().reference()

        // Do any additional setup after loading the view.
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        if let email = Auth.auth().currentUser?.email {
            // check if rider has been placed a call already
            appDB.child("RideRequests").queryOrdered(byChild: "email").queryEqual(toValue: email).observe(.childAdded, with: { (snapshot) in
                self.driverCalled = true
                self.callDriver.setTitle("Cancel your call", for: .normal)
                // stop observing after the query
                self.appDB.child("RideRequests").removeAllObservers()
                
                // check if the placed call is accepted by driver already
                if let driverRequest = snapshot.value as? [String:AnyObject] {
                    if let driverLat = driverRequest["driverLat"] as? Double {
                        if let driverLon = driverRequest["driverLon"] as? Double {
                            self.driverLocation = CLLocationCoordinate2D(latitude: driverLat, longitude: driverLon)
                            
                            self.driverAccepted = true
                            self.displayDriverAndRider()
                            
                            // set observer to reposition both rider and driver if one of them is moving
                            self.appDB.child("RideRequests").queryOrdered(byChild: "email").queryEqual(toValue: email).observe(.childChanged, with: { (snapshot) in
                                self.displayDriverAndRider()
                                // note observer is not stopped
                            })
                        }
                    }
                }
            })
        }
    }
    
    // updates and shows both rider and driver and updates button
    func displayDriverAndRider() {
        // distance between both calculation
        let driverCLLocation = CLLocation(latitude: driverLocation.latitude, longitude: driverLocation.longitude)
        let riderCLLocation = CLLocation(latitude: riderLocation.latitude, longitude: riderLocation.longitude)
        let distance = driverCLLocation.distance(from: riderCLLocation) / 1000
        let roundedDistance = round(distance * 100) / 100
        
        // update the button with the distance
        callDriver.setTitle("Your driver is \(roundedDistance)km away!", for: .normal)
        map.removeAnnotations(map.annotations)
        
        // set up map with space 0.005 outsides
        let latDelta = abs(driverLocation.latitude - riderLocation.latitude) * 2 + 0.005
        let lonDelta = abs(driverLocation.longitude - riderLocation.longitude) * 2 + 0.005
        let region = MKCoordinateRegion(center: riderLocation, span: MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta))
        map.setRegion(region, animated: true)
        
        // show both annotations
        let riderAnno = MKPointAnnotation()
        riderAnno.coordinate = riderLocation
        riderAnno.title = "You"
        map.addAnnotation(riderAnno)
        let driverAnno = MKPointAnnotation()
        driverAnno.coordinate = driverLocation
        driverAnno.title = "Driver"
        map.addAnnotation(driverAnno)
    }
    
    // updates and shows rider location or both rider and driver( if accepted ) locations via above func
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let coord = manager.location?.coordinate {
            let center = CLLocationCoordinate2D(latitude: coord.latitude, longitude: coord.longitude)
            riderLocation = center
            
            if driverAccepted {  // show both rider and driver continuously
                displayDriverAndRider()
            } else { // show only rider continuously
                let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
                map.setRegion(region, animated: true)
                // do not pile lots of bubbles there
                map.removeAnnotations(map.annotations)
                // just one bubble
                let annotation = MKPointAnnotation()
                annotation.coordinate = center
                annotation.title = "You"
                map.addAnnotation(annotation)
            }            
        }
    }
    
    // add/remove driver db driver request and toggle the button
    @IBAction func callADriverPressed(_ sender: Any) {
        if let email = Auth.auth().currentUser?.email {
            
            if driverCalled {  // driver call is placed
                driverCalled = false
                callDriver.setTitle("Call a driver", for: .normal)
                // driverAccepted = false // to cancel driver request NOT politely?
                
                // query and delete placed calls
                appDB.child("RideRequests").queryOrdered(byChild: "email").queryEqual(toValue: email).observe(.childAdded, with: { (snapshot) in
                    snapshot.ref.removeValue() // remove matches
                    // stop observing, so subsequent requests will not be removed
                    self.appDB.child("RideRequests").removeAllObservers()
                })
            } else {  // driver call is not placed
                driverCalled = true
                callDriver.setTitle("Cancel your call", for: .normal)
                // amend call to db
                let driverRequest : [String:Any] = ["email":email,"lat":riderLocation.latitude,"lon":riderLocation.longitude]
                appDB.child("RideRequests").childByAutoId().setValue(driverRequest)
            }
        }
    }
    
    // just a log out
    @IBAction func LogOutPressed(_ sender: Any) {
        try? Auth.auth().signOut()
        debugPrint("Log Out success")
        navigationController?.dismiss(animated: true, completion: nil)
    }
}
