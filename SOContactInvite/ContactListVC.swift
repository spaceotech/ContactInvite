//
//  ContactListVC.swift
//  SOContactInvite
//
//  Created by Hitesh on 9/19/16.
//  Copyright © 2016 myCompany. All rights reserved.
//

import UIKit
import AddressBook
import MessageUI

enum FetchType {
    case Email
    case PhoneNumber
    case BothPhoneAndEmail
}

class ContactListVC: UIViewController, MFMailComposeViewControllerDelegate, MFMessageComposeViewControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var tblContacts: UITableView!
    var arrContacts = NSMutableArray()
    var arrSearch = NSMutableArray()
    var arrSelectedContacts = NSMutableArray()
    var arrCharacters = NSMutableArray()
    var dictSections = [NSObject : AnyObject]()
    
    var contactType : FetchType = .BothPhoneAndEmail
    
    lazy var addressBook: ABAddressBookRef = {
        var error: Unmanaged<CFError>?
        return ABAddressBookCreateWithOptions(nil,
                                              &error).takeRetainedValue() as ABAddressBookRef
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        SOGetPermissionContactAccess()
    }
    
    //MARK: GET PERMISSION FOR ACCESS ADDRESS BOOK
    
    func SOGetPermissionContactAccess() {
        
        switch ABAddressBookGetAuthorizationStatus(){
        case .Authorized:
            //Able to fetch authorize
            SOGetAddressBookRecord(contactType)
            break
        case .Denied:
            //User not allowed to access contect list
            break
        case .NotDetermined:
            if let theBook: ABAddressBookRef = addressBook{
                ABAddressBookRequestAccessWithCompletion(theBook,
                                                         {granted, error in
                                                            if granted{
                                                                self.SOGetAddressBookRecord(self.contactType)
                                                            } else {
                                                                
                                                            }
                                                            
                })
            }
            
        case .Restricted:
            break
            
            
        }
    }
    
    
    
    //MARK: GET RECORDS FROM ADDRESS BOOK
    func SOGetAddressBookRecord(type: FetchType) {
        let arrContactList = NSMutableArray()
        
        /* Get all the people in the address book */
        let allPeople = ABAddressBookCopyArrayOfAllPeople(
            addressBook).takeRetainedValue() as NSArray
        
        for person: ABRecordRef in allPeople{
            var dictPerson:Dictionary = [String:AnyObject]()
            var firstName: String = ""
            var lastName: String = ""
            
            
            let isFirstName: Bool = (ABRecordCopyValue(person, kABPersonFirstNameProperty) != nil)
            let isLastName: Bool = (ABRecordCopyValue(person, kABPersonLastNameProperty) != nil)
            if isFirstName {
                firstName = (ABRecordCopyValue(person,
                    kABPersonFirstNameProperty).takeUnretainedValue() as? String)!
                dictPerson["first_name"] = firstName
            }
            if isLastName {
                lastName = (ABRecordCopyValue(person,
                    kABPersonLastNameProperty).takeUnretainedValue() as? String)!
                dictPerson["last_name"] = lastName
            }
            
            var strFullName: String = "\(firstName) \(lastName)"
            strFullName = strFullName.stringByReplacingOccurrencesOfString("\"", withString: "")
            strFullName = strFullName.stringByReplacingOccurrencesOfString("''", withString: "'")
            dictPerson["contact_name"] = strFullName
            let recordId: Int = Int(ABRecordGetRecordID(person))
            dictPerson["RecordID"] = recordId
            
            if(ABPersonHasImageData(person)){
                
            } else {
                
            }
            
            if type == FetchType.BothPhoneAndEmail {
                //Get Emails of contact
                let emails: ABMultiValueRef = ABRecordCopyValue(person,
                                                                kABPersonEmailProperty).takeRetainedValue()
                
                if ABMultiValueGetCount(emails)>0 {
                    var arrEmail = [AnyObject]()
                    
                    for counter in 0..<ABMultiValueGetCount(emails){
                        let email = ABMultiValueCopyValueAtIndex(emails,
                                                                 counter).takeRetainedValue() as! String
                        arrEmail.append(email)
                    }
                    dictPerson["email"] = arrEmail
                }
                
                
                //Get Phone Numbers of contact
                let phones: ABMultiValueRef = ABRecordCopyValue(person,
                                                                kABPersonPhoneProperty).takeRetainedValue()
                
                if ABMultiValueGetCount(phones)>0 {
                    var arrPhone = [AnyObject]()
                    
                    for counter in 0..<ABMultiValueGetCount(phones){
                        let phone = ABMultiValueCopyValueAtIndex(phones,
                                                                 counter).takeRetainedValue() as! String
                        arrPhone.append(phone)
                    }
                    
                    dictPerson["phone"] = arrPhone
                }
                
                if isFirstName == true || isLastName == true {
                    arrContactList.addObject(dictPerson)
                }
                
            } else if type == FetchType.Email {
                //Get Emails of contact
                let emails: ABMultiValueRef = ABRecordCopyValue(person,
                                                                kABPersonEmailProperty).takeRetainedValue()
                
                if ABMultiValueGetCount(emails)>0 {
                    var arrEmail = [AnyObject]()
                    
                    for counter in 0..<ABMultiValueGetCount(emails){
                        let email = ABMultiValueCopyValueAtIndex(emails,
                                                                 counter).takeRetainedValue() as! String
                        arrEmail.append(email)
                    }
                    
                    dictPerson["email"] = arrEmail
                    if isFirstName == true || isLastName == true {
                        arrContactList.addObject(dictPerson)
                    }
                }
            } else {
                //Get Phone Numbers of contact
                let phones: ABMultiValueRef = ABRecordCopyValue(person,
                                                                kABPersonPhoneProperty).takeRetainedValue()
                
                if ABMultiValueGetCount(phones)>0 {
                    var arrPhone = [AnyObject]()
                    
                    for counter in 0..<ABMultiValueGetCount(phones){
                        let phone = ABMultiValueCopyValueAtIndex(phones,
                                                                 counter).takeRetainedValue() as! String
                        arrPhone.append(phone)
                    }
                    
                    dictPerson["phone"] = arrPhone
                    if isFirstName == true || isLastName == true {
                        arrContactList.addObject(dictPerson)
                    }
                }
            }
        }
        
        let descriptor: NSSortDescriptor = NSSortDescriptor(key:"contact_name", ascending: true, selector: #selector(NSString.localizedCaseInsensitiveCompare(_:)))
        
        let sortedResults: NSArray = arrContactList.sortedArrayUsingDescriptors([descriptor])
        self.initilizeTable(sortedResults as [AnyObject])
    }
    
    
    func initilizeTable(listArray: [AnyObject]) {
        let arrSectionData = NSMutableArray()
        arrCharacters = NSMutableArray()
        self.dictSections = [NSObject : AnyObject]()
        
        var strFirstLetter: String
        for dict in listArray {
            let strData: String = (dict["contact_name"] as! String)
            let index: String.Index = strData.startIndex.advancedBy(1)
            strFirstLetter = strData.substringToIndex(index).uppercaseString
            if ((dictSections[strFirstLetter]) == nil) {
                arrSectionData.removeAllObjects()
                arrCharacters.addObject("\(strFirstLetter)")
            }
            arrSectionData.addObject(dict)
            dictSections["\(strFirstLetter)"] = arrSectionData.copy()
        }
        print(dictSections)
        print(arrCharacters)
        tblContacts!.reloadData()
    }
    
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 54
    }
    
    
    //MARK: UITableViewDataSource
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return arrCharacters.count
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let strLetter: String = arrCharacters[section] as! String
        let arrData: [AnyObject] = (dictSections[strLetter] as! [AnyObject])
        return arrData.count
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String {
        if arrCharacters.count == 0 {
            return ""
        }
        return arrCharacters[section] as! String
    }
    
    func sectionIndexTitlesForTableView(tableView: UITableView) -> [AnyObject] {
        let indexArray: [AnyObject] = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"]
        return indexArray
    }
    
    func tableView(tableView: UITableView, sectionForSectionIndexTitle title: String, atIndex index: Int) -> Int {
        var clickIndex: Int = 0
        for strCharacter in arrCharacters {
            if (strCharacter as! String == title) {
                tblContacts!.scrollToRowAtIndexPath(NSIndexPath(forRow: 0, inSection: clickIndex), atScrollPosition: .Top, animated: true)
                return clickIndex
            }
            clickIndex += 1
        }
        return 0
    }
    
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) 
        configureCell(cell, forRowAtIndexPath: indexPath)
        return cell
    }
    
    func configureCell(cell: UITableViewCell, forRowAtIndexPath: NSIndexPath) {
        let strIndexNames: String = arrCharacters[forRowAtIndexPath.section] as! String
        var arrIndexedCategories: [AnyObject] = (dictSections[strIndexNames] as! [AnyObject])
        var dict: [String : AnyObject] = arrIndexedCategories[forRowAtIndexPath.row] as! [String : AnyObject]
        
        
        let label = UILabel(frame: CGRectMake(20, 10, 200, 21))
        label.textAlignment = NSTextAlignment.Left
        label.text = dict["contact_name"] as? String
        cell.contentView.addSubview(label)
        
        if contactType == .PhoneNumber {
            let arrPhone = dict["phone"] as! NSArray
            if arrPhone.count > 0 {
                let strPhone = arrPhone[0] as! NSString
                if arrSelectedContacts.containsObject(strPhone) {
                    cell.accessoryType = UITableViewCellAccessoryType.Checkmark
                } else {
                    cell.accessoryType = UITableViewCellAccessoryType.None
                }
            }
        } else {
            let arrEmail = dict["email"] as! NSArray
            if arrEmail.count > 0 {
                let strEmail = arrEmail[0] as! NSString
                if arrSelectedContacts.containsObject(strEmail) {
                    cell.accessoryType = UITableViewCellAccessoryType.Checkmark
                } else {
                    cell.accessoryType = UITableViewCellAccessoryType.None
                }
            }
        }
    }
    
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let strIndexNames: String = arrCharacters[indexPath.section] as! String
        var arrIndexedCategories: [AnyObject] = (dictSections[strIndexNames] as! [AnyObject])
        var dict: [String : AnyObject] = arrIndexedCategories[indexPath.row] as! [String : AnyObject]
        
        if contactType == .PhoneNumber {
            let arrPhone = dict["phone"] as! NSArray
            if arrPhone.count > 0 {
                let strPhone = arrPhone[0] as! NSString
                if arrSelectedContacts.containsObject(strPhone) {
                    arrSelectedContacts.removeObject(strPhone)
                }
                else {
                    arrSelectedContacts.addObject(strPhone)
                }
            }
        } else {
            let arrEmail = dict["email"] as! NSArray
            if arrEmail.count > 0 {
                let strEmail = arrEmail[0] as! NSString
                
                if arrSelectedContacts.containsObject(strEmail) {
                    arrSelectedContacts.removeObject(strEmail)
                }
                else {
                    arrSelectedContacts.addObject(strEmail)
                }
            }
        }
        
        tblContacts?.reloadData()
    }
    
    
    @IBAction func actionSend(sender: AnyObject) {
        if contactType == .PhoneNumber {
            presentModalMessageComposeViewController(true)
        } else {
            presentModalMailComposeViewController(true)
        }
    }
    
    //MARK: MFMessageComposeViewController
    // 'import MessageUI' where you want to intigrate Message composer
    func presentModalMessageComposeViewController(animated: Bool) {
        if MFMessageComposeViewController.canSendText() {
            let arrRecipients = arrSelectedContacts as NSArray as! [String]
            
            let messageComposeVC = MFMessageComposeViewController()
            messageComposeVC.messageComposeDelegate = self
            messageComposeVC.body = "Sending Friend Request"
            messageComposeVC.recipients = arrRecipients
            
            presentViewController(messageComposeVC, animated: animated, completion: nil)
            
        } else {
            UIAlertView(title: NSLocalizedString("Error", value: "Error", comment: ""), message: NSLocalizedString("Your device doesn't support messaging", value: "Your device doesn't support messaging", comment: ""), delegate: nil, cancelButtonTitle: NSLocalizedString("OK", value: "OK", comment: "")).show()
        }
    }
    
    func messageComposeViewController(controller: MFMessageComposeViewController, didFinishWithResult result: MessageComposeResult) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    //MARK: MFMailComposeViewController
    // 'import MessageUI' where you want to use mail composer sheet
    func presentModalMailComposeViewController(animated: Bool) {
        if MFMailComposeViewController.canSendMail() {
            let arrRecipients = arrSelectedContacts as NSArray as! [String]
            
            let mailComposeVC = MFMailComposeViewController()
            mailComposeVC.delegate = self
            mailComposeVC.setSubject("Invite Friends")
            mailComposeVC.setMessageBody("Sending Friend Request", isHTML: true)
            mailComposeVC.setToRecipients(arrRecipients)
            
            presentViewController(mailComposeVC, animated: animated, completion: nil)
        } else {
            UIAlertView(title: NSLocalizedString("Error", value: "Error", comment: ""), message: NSLocalizedString("Your device doesn't support Mail messaging", value: "Your device doesn't support Mail messaging", comment: ""), delegate: nil, cancelButtonTitle: NSLocalizedString("OK", value: "OK", comment: "")).show()
        }
    }
    
    //MARK: MFMailComposeViewControllerDelegate
    
    func mailComposeController(controller: MFMailComposeViewController, didFinishWithResult result: MFMailComposeResult, error: NSError?) {
        
        if error != nil {
            print("Error: \(error)")
        }
        
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func actionBack(sender: AnyObject) {
        self.navigationController?.popViewControllerAnimated(true)
    }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
