import UIKit
import MapKit
import FirebaseDatabase

class AcceptRequestViewController: UIViewController {
    
    @IBOutlet weak var map: MKMapView!
    
    var riderLocation = CLLocationCoordinate2D()     // configured in DriverTableVC
    var driverLocation = CLLocationCoordinate2D()    // configured in DriverTableVC
    var riderEmail = ""                            // configured in DriverTableVC
    var appDB : DatabaseReference!
    
    // display rider of interest
    override func viewDidLoad() {
        super.viewDidLoad()
        
        appDB = Database.database().reference()
        
        let region = MKCoordinateRegion(center: riderLocation, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
        map.setRegion(region, animated: false)
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = riderLocation
        annotation.title = riderEmail
        map.addAnnotation(annotation)
    }
    
    // update db and get directions
    @IBAction func acceptRequestPressed(_ sender: Any) {
        // Update the ride Request in db
        appDB.child("RideRequests").queryOrdered(byChild: "email").queryEqual(toValue: riderEmail).observe(.childAdded) { (snapshot) in
            snapshot.ref.updateChildValues(["driverLat":self.driverLocation.latitude, "driverLon":self.driverLocation.longitude])
            self.appDB.child("RideRequests").removeAllObservers()
        }
        
        // Give directions
        let requestCLLocation = CLLocation(latitude: riderLocation.latitude, longitude: riderLocation.longitude)
        
        CLGeocoder().reverseGeocodeLocation(requestCLLocation) { (placemarks, error) in
            if let placemarks = placemarks {
                if placemarks.count > 0 {
                    let placeMark = MKPlacemark(placemark: placemarks[0])
                    let mapItem = MKMapItem(placemark: placeMark)
                    mapItem.name = self.riderEmail
                    let options = [MKLaunchOptionsDirectionsModeKey:MKLaunchOptionsDirectionsModeDriving]
                    mapItem.openInMaps(launchOptions: options)
                }
            }
        }
    }    
}
