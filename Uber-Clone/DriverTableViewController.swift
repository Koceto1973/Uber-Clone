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
        
        appDB.child("RideRequests").observe(.childAdded) { (snapshot) in
            // the accepted requsets by drivers are not listed anymore
            if let driverRequest = snapshot.value as? [String:AnyObject] {
                if let lat = driverRequest["lat"] as? Double {
                    // ???
                } else {
                    self.rideRequests.append(snapshot)
                    self.tableView.reloadData()
                }
            }
        }
        // periodical monitor for new requests
        Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { (timer) in
            self.tableView.reloadData()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let coord = manager.location?.coordinate {
            driverLocation = coord
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rideRequests.count
    }
    
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
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // accepting the rider's call
        performSegue(withIdentifier: "acceptSegue", sender: rideRequests[indexPath.row])
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let acceptVC = segue.destination as? AcceptRequestViewController {
            if let snapshot = sender as? DataSnapshot {
                if let rideRequestDictionary = snapshot.value as? [String:AnyObject] {
                    if let email = rideRequestDictionary["email"] as? String {
                        if let lat = rideRequestDictionary["lat"] as? Double {
                            if let lon = rideRequestDictionary["lon"] as? Double {
                                acceptVC.requestEmail = email
                                let location = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                                acceptVC.requestLocation = location
                                acceptVC.driverLocation = driverLocation
                            }
                        }
                    }
                }
            }
        }
    }
    
    @IBAction func logOutPressed(_ sender: Any) {
        try? Auth.auth().signOut()
        navigationController?.dismiss(animated: true, completion: nil)
    }
}
