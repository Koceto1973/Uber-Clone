//
//  DriverTableViewController.swift
//  Uber-Clone
//
//  Created by K.K. on 4.11.18.
//  Copyright © 2018 K.K. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase
import MapKit

class DriverTableViewController: UITableViewController, CLLocationManagerDelegate {
    
    var rideRequests : [DataSnapshot] = []
    var locationManager = CLLocationManager()
    var driverLocation  = CLLocationCoordinate2D()
    var appDB : DatabaseReference!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        appDB = Database.database().reference()
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        // continuous observer for driver requests addition
        appDB.child("RideRequests").observe(.childAdded) { (snapshot) in
            // the accepted requsets by drivers are not listed anymore
            if let driverRequest = snapshot.value as? [String:AnyObject] {
                if (driverRequest["driverLat"] as? Double) == nil {
                    self.rideRequests.append(snapshot)
                    self.tableView.reloadData()
                }                
            }
        }
        
        // periodical table updates to show observer additions if any
        Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { (timer) in
            self.tableView.reloadData()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let coord = manager.location?.coordinate {
            driverLocation = coord
        }
    }
    
    // driver requests table view rows set up
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rideRequests.count
    }
    
    // driver requests table view cell set up
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "rideReqestCell", for: indexPath)
        // configure cell to show distance to each rider
        if let driverRequest = rideRequests[indexPath.row].value as? [String:AnyObject] {
            if let email = driverRequest["email"] as? String {
                if let lat = driverRequest["lat"] as? Double {
                    if let lon = driverRequest["lon"] as? Double {
                        let driverCLLocation = CLLocation(latitude: driverLocation.latitude, longitude: driverLocation.longitude)
                        let riderCLLocation = CLLocation(latitude: lat, longitude: lon)
                        let distance = driverCLLocation.distance(from: riderCLLocation) / 1000
                        let roundedDistance = round(distance * 100) / 100
                        cell.textLabel?.text = "\(email) - \(roundedDistance)km away"
                    }
                }
            }
        }
        return cell
    }
    
    // pass rider request data to accept request VC
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let acceptVC = segue.destination as? AcceptRequestViewController {
            if let snapshot = sender as? DataSnapshot {  // sender: rideRequests[indexPath.row]
                if let rideRequest = snapshot.value as? [String:AnyObject] {
                    if let email = rideRequest["email"] as? String { 
                        if let lat = rideRequest["lat"] as? Double {
                            if let lon = rideRequest["lon"] as? Double {
                                acceptVC.riderEmail = email
                                let riderLocation = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                                acceptVC.riderLocation = riderLocation
                                acceptVC.driverLocation = driverLocation
                            }
                        }
                    }
                }
            }
        }
    }
    
    // segue to accept request VC when driver request is selected
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // accepting the rider's call
        performSegue(withIdentifier: "acceptSegue", sender: rideRequests[indexPath.row])
    }
    
    // just a driver logout
    @IBAction func logOutPressed(_ sender: Any) {
        try? Auth.auth().signOut()
        navigationController?.dismiss(animated: true, completion: nil)
    }
}
