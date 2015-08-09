//
//  ViewController.swift
//  flickFinder
//
//  Created by Leo Picado on 8/8/15.
//  Copyright (c) 2015 LeoPicado. All rights reserved.
//

import UIKit
import Alamofire
import MBProgressHUD

class ViewController: UIViewController, UITextFieldDelegate {
    let APIKey = "3e7353f8113a17dc4191df91e733fd2d"
    let baseURL = "https://api.flickr.com/services/rest/"
    
    @IBOutlet var lblCaption:UILabel!
    @IBOutlet var imgMain:UIImageView!
    @IBOutlet var txtSearchByPhrase:UITextField!
    @IBOutlet var txtSearchByLat:UITextField!
    @IBOutlet var txtSearchByLong:UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        txtSearchByLat.delegate = self
        txtSearchByLong.delegate = self
        txtSearchByPhrase.delegate = self
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        unsubscribeFromKeyboardNotifications()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        imgMain.alpha = 0.0
        lblCaption.alpha = 0.0
        subscribeToKeyboardNotifications()
    }
    
    // MARK: Keyboard sliding
    /**
    The height of the keyboard can come from multiple places, ie: bluetooth
    keyboards, custom keyboards, so it's best to calculate it.
    
    :param: notification fired from `UIKeyboardWillShowNotification`
    
    :returns: height of the current keyboard on screen
    */
    func getKeyboardHeight(notification: NSNotification) -> CGFloat {
        if let userInfo = notification.userInfo,
            keyboardSize = userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue {
                return keyboardSize.CGRectValue().height
        }
        
        return 0
    }
    
    /**
    Slide the frame down.
    */
    func keyboardWillHide(notification: NSNotification) {
        self.view.frame.origin.y += getKeyboardHeight(notification)
    }
    
    /**
    Slide the frame up.
    */
    func keyboardWillShow(notification: NSNotification) {
        self.view.frame.origin.y -= getKeyboardHeight(notification)
    }
    
    func subscribeToKeyboardNotifications() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillShow:",
            name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillHide:",
            name: UIKeyboardWillHideNotification, object: nil)
    }
    
    func unsubscribeFromKeyboardNotifications() {
        NSNotificationCenter.defaultCenter().removeObserver(self, name:
            UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name:
            UIKeyboardWillHideNotification, object: nil)
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        tapOnSearchBtn()
        return true
    }
    
    @IBAction func tapOnSearchBtn() {
        let lat = txtSearchByLat.text
        let lon = txtSearchByLong.text
        let phrase = txtSearchByPhrase.text
        let noSearchTerm = lat.isEmpty && lon.isEmpty && phrase.isEmpty
        
        if isValidSearch() {
            var params:[String:AnyObject] = [
                "api_key": APIKey,
                "format": "json",
                "method": "flickr.photos.search",
                "nojsoncallback": 1,
                "per_page": 10
            ]
            
            if !phrase.isEmpty {
                params["text"] = phrase
            }
            
            if !lat.isEmpty && !lon.isEmpty {
                params["lat"] = lat
                params["lon"] = lon
            }
            
            searchImage(baseURL, params: params)
        } else {
            println("Can not go on without something to search.")
        }
    }
    
    func searchImage(baseURL:String, params:[String:AnyObject]) {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        MBProgressHUD.showHUDAddedTo(self.view, animated: true)
        
        UIView.animateWithDuration(0.5, animations: { () -> Void in
            self.imgMain.alpha = 0.0
            self.lblCaption.alpha = 0.0
        })
        
        Alamofire.request(.GET, baseURL, parameters: params).responseJSON { _, _, JSON, error in
            if error == nil {
                if let data = JSON as? NSDictionary {
                    if let photos = data.valueForKey("photos")?.valueForKey("photo") as? [NSDictionary] {
                        let photo = photos.sample
                        let farmId = photo.valueForKey("farm") as! NSNumber
                        let serverId = photo.valueForKey("server") as! String
                        let photoId = photo.valueForKey("id") as! String
                        let secret = photo.valueForKey("secret") as! String
                        let title = photo.valueForKey("title") as! String
                        let size = "z"
                        let photoURL = "https://farm\(farmId).staticflickr.com/\(serverId)/\(photoId)_\(secret)_\(size).jpg"
                        
                        Alamofire.request(.GET, photoURL).response { (_, _, imgData, error) in
                            self.imgMain.image = UIImage(data: imgData!)
                            
                            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                            MBProgressHUD.hideHUDForView(self.view, animated: true)
                            self.lblCaption.text = title
                            
                            UIView.animateWithDuration(0.5, animations: { () -> Void in
                                self.imgMain.alpha = 1.0
                                self.lblCaption.alpha = 1.0
                            })
                        }
                    }
                }
            }
        }
    }
    
    func isValidSearch() -> Bool {
        let lat = txtSearchByLat.text
        let lon = txtSearchByLong.text
        let phrase = txtSearchByPhrase.text
        let noSearchTerm = lat.isEmpty && lon.isEmpty && phrase.isEmpty

        if !phrase.isEmpty {
            return true
        }
        
        if !lon.isEmpty && !lat.isEmpty {
            return true
        }
        
        return noSearchTerm
    }
    
}
