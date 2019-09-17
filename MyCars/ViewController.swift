//
//  ViewController.swift
//  MyCars
//
//  Created by Ivan Akulov on 07/11/16.
//  Copyright © 2016 Ivan Akulov. All rights reserved.
//

import UIKit
import CoreData

class ViewController: UIViewController {
    
    var selectedCar: Car!
    var context: NSManagedObjectContext!
    //  lazy var context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var markLabel: UILabel!
    @IBOutlet weak var modelLabel: UILabel!
    @IBOutlet weak var carImageView: UIImageView!
    @IBOutlet weak var lastTimeStartedLabel: UILabel!
    @IBOutlet weak var numberOfTripsLabel: UILabel!
    @IBOutlet weak var ratingLabel: UILabel!
    @IBOutlet weak var myChoiceImageView: UIImageView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        getDataFromFile()
        
        let fetchRequest: NSFetchRequest<Car> = Car.fetchRequest()
        let mark = segmentedControl.titleForSegment(at: 0)
        fetchRequest.predicate = NSPredicate(format: "mark == %@", mark!)
        
        do {
            let results = try context.fetch(fetchRequest)
            selectedCar = results[0]
            insertDataFrom(selectedCar: selectedCar)
        } catch {
            print(error.localizedDescription)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func insertDataFrom(selectedCar: Car) {
        
        carImageView.image = UIImage(data: selectedCar.imageData!)
        markLabel.text = selectedCar.mark
        modelLabel.text = selectedCar.model
        myChoiceImageView.isHidden = !(selectedCar.myChoice?.boolValue)!
        ratingLabel.text = "Rating: \(selectedCar.rating!.doubleValue) / 10.0"
        numberOfTripsLabel.text = "Number of tips: \(selectedCar.timesDriven!.intValue)"
        
        let df = DateFormatter()
        df.dateStyle = .short
        df.timeStyle = .none
        lastTimeStartedLabel.text = "Last time started: \(df.string(from: selectedCar.lastStarted! as Date))"
        
        segmentedControl.tintColor = selectedCar.tintColor as? UIColor
    }
    
    func getDataFromFile() {
        let fetchRequest: NSFetchRequest<Car> = Car.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "mark != nil") // не делает сейчас ничего. для примера
        
        var records = 0
        
        do {
            let count = try context.count(for: fetchRequest)
            records = count
            print("Data is theere already?")
        } catch {
            print(error.localizedDescription)
        }
        
        guard records == 0 else { return }
        
        let pathToFile = Bundle.main.path(forResource: "data", ofType: "plist")
        let dataArray = NSArray(contentsOfFile: pathToFile!)!
        
        for dictionary in dataArray {
            let entity = NSEntityDescription.entity(forEntityName: "Car", in: context)
            let car = NSManagedObject(entity: entity!, insertInto: context) as! Car
            
            let carDictionary = dictionary as! NSDictionary
            car.mark = carDictionary["mark"] as? String
            car.model = carDictionary["model"] as? String
            car.rating = carDictionary["rating"] as? NSNumber
            car.lastStarted = carDictionary["lastStarted"] as? NSDate as Date?
            car.timesDriven = carDictionary["timesDriven"] as? NSNumber
            car.myChoice = carDictionary["myChoice"] as? NSNumber
            
            let imageName = carDictionary["imageName"] as? String
            let image = UIImage(named: imageName!)
            let imageData = image!.pngData()
            car.imageData = imageData as NSData? as Data?
            
            let colorDictionary = carDictionary["tintColor"] as? NSDictionary
            car.tintColor = getColor(colorDictionary: colorDictionary!)
        }
        
    }
    
    func getColor(colorDictionary: NSDictionary) -> UIColor {
        let red = colorDictionary["red"] as! NSNumber
        let green = colorDictionary["green"] as! NSNumber
        let blue = colorDictionary["blue"] as! NSNumber
        
        return UIColor(red: CGFloat(red.floatValue) / 255, green: CGFloat(green.floatValue) / 255, blue: CGFloat(blue.floatValue) / 255, alpha: 1.0)
    }
    
    @IBAction func segmentedCtrlPressed(_ sender: UISegmentedControl) {
        
        let mark = sender.titleForSegment(at: sender.selectedSegmentIndex)
        let fetchRequest: NSFetchRequest<Car> = Car.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "mark == %@", mark!)
        
        do {
            let results = try context.fetch(fetchRequest)
            selectedCar = results[0]
            insertDataFrom(selectedCar: selectedCar)
        } catch {
            print(error.localizedDescription)
        }
    }
    
    @IBAction func startEnginePressed(_ sender: UIButton) {
        
        let timesDriven = selectedCar.timesDriven?.intValue
        selectedCar.timesDriven = NSNumber(value: timesDriven! + 1)
        selectedCar.lastStarted = NSDate() as Date
        
        do {
            try context.save()
            insertDataFrom(selectedCar: selectedCar)
        } catch {
            print(error.localizedDescription)
        }
    }
    
    @IBAction func rateItPressed(_ sender: UIButton) {
        
        let ac = UIAlertController(title: "Rated", message: "Rate this car please", preferredStyle: .alert)
        let ok = UIAlertAction(title: "Ok", style: .default) { action in
            let textField = ac.textFields?[0]
            self.update(rating: textField!.text!)
        }
        let cancel = UIAlertAction(title: "Cancel", style: .default)
        
        ac.addTextField { (textField) in
            textField.keyboardType = .numberPad
        }
        ac.addAction(ok)
        ac.addAction(cancel)
        present(ac, animated: true)
    }
    
    func update(rating: String) {
        
        selectedCar.rating = NSNumber(value: Double(rating)!)
        
        do {
            try context.save()
            insertDataFrom(selectedCar: selectedCar)
        } catch {
            let ac = UIAlertController(title: "Wrong value", message: "Wrong input", preferredStyle: .alert)
            let ok = UIAlertAction(title: "Ok", style: .default)
            ac.addAction(ok)
            present(ac, animated: true, completion: nil)
            print(error.localizedDescription)
        }
    }
}

