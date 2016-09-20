//
//  ViewController.swift
//  SOContactInvite
//
//  Created by Hitesh on 9/19/16.
//  Copyright © 2016 myCompany. All rights reserved.
//



import UIKit


class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    @IBAction func actionContactListByPhone(sender: AnyObject) {
        let objController = self.storyboard?.instantiateViewControllerWithIdentifier("ContactListVCID") as! ContactListVC
        objController.contactType = .PhoneNumber
        self.navigationController?.pushViewController(objController, animated: true)
    }
    
    
    @IBAction func actionContactListByEmail(sender: AnyObject) {
        let objController = self.storyboard?.instantiateViewControllerWithIdentifier("ContactListVCID") as! ContactListVC
        objController.contactType = .Email
        self.navigationController?.pushViewController(objController, animated: true)
        
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

