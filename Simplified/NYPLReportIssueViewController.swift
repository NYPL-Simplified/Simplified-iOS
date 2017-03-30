//
//  NYPLReportIssueViewController.swift
//  Simplified
//
//  Created by Aferdita Muriqi on 3/29/17.
//  Copyright © 2017 NYPL Labs. All rights reserved.
//

import UIKit
import HelpStack
import MessageUI

class NYPLReportIssueViewController: UITableViewController, UITextFieldDelegate, UITextViewDelegate, MFMailComposeViewControllerDelegate {
  
  var subjectField: UITextField!
  
  var messageField: HSTextViewInternal!
  var submitBarItem:UIBarButtonItem!;
  var account:Account!
  
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    let appearance:HSAppearance = (HSHelpStack.instance() as AnyObject).appearance
    self.view.backgroundColor = appearance.getBackgroundColor()
    submitBarItem = UIBarButtonItem.init(title: "Submit", style: .done, target: self, action:  #selector(submitPressed(sender:)))
    
    self.navigationItem.rightBarButtonItem = submitBarItem
    
  }
  func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
    
    self.dismiss(animated: true, completion: nil)
    
    switch result {
    case .sent:
      self.navigationController?.popViewController(animated: false)
      break
    case .saved:
      self.navigationController?.popViewController(animated: false)
      break
    case .cancelled:
      subjectField.becomeFirstResponder()
      break
    case .failed:
      subjectField.becomeFirstResponder()
      break
    }
  }
  
  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    if(textField == subjectField) {
      messageField.becomeFirstResponder()
      return true;
    }
    return false
  }
  
  func checkValidity() -> Bool
  {
    if subjectField.text!.isEmpty {
      let alert = UIAlertView.init(title: "Missing Subject", message: "Please enter a subject", delegate: nil, cancelButtonTitle: "OK")
      alert.show()
      return false
    }
    if messageField.text!.isEmpty {
      let alert = UIAlertView.init(title: "Missing Message", message: "Please enter a message", delegate: nil, cancelButtonTitle: "OK")
      alert.show()
      return false
    }
    return true
  }
  
  
  func submitPressed(sender:Any)
  {
    if checkValidity() {
      
      let messageContent:NSMutableString = NSMutableString.init(string: messageField.text);
      messageContent.append(HSUtility.deviceInformation())
      
      let mailVC:MFMailComposeViewController = MFMailComposeViewController();
      mailVC.mailComposeDelegate = self;
      mailVC.setSubject(subjectField.text!);
      mailVC.setMessageBody(messageContent as String, isHTML: false);
      mailVC.setToRecipients([account.supportEmail!]);
      self.present(mailVC, animated: true, completion: nil)
      
    }
    
  }
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    // #warning Incomplete implementation, return the number of rows
    return 2
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    
    var cell = UITableViewCell.init(style: .subtitle, reuseIdentifier: "")
    
    let SubjectCellIdentifier = "Cell_Subject";
    let MessageCellIdentifier = "Cell_Message";
    if(indexPath.row == 0) {
      cell = tableView.dequeueReusableCell(withIdentifier: SubjectCellIdentifier, for: indexPath)
      subjectField =  cell.viewWithTag(11) as! UITextField!
      
      subjectField.delegate = self;
      
      subjectField.becomeFirstResponder()
      
    }
    else if(indexPath.row == 1) {
      cell = tableView.dequeueReusableCell(withIdentifier: MessageCellIdentifier, for: indexPath)
      
      messageField =  cell.viewWithTag(12) as! HSTextViewInternal!
      
      var messageFrame = messageField.frame;
      messageFrame.size.height = cell.frame.size.height - 40.0;
      messageField.frame = messageFrame;
      messageField.delegate = self;
      
    }
    
    return cell;
    
  }
  
  override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    
    if HSAppearance.isIPad()
    {
      if(indexPath.row == 0){
        return 44.0;
      }else if(indexPath.row == 1){
        return self.view.frame.size.height - 44.0;
      }else{
        return 44.0;
      }
    }
    else{
      if(indexPath.row == 0) {
        return 44.0;
      }
      else if(indexPath.row == 1) {
        var messageHeight:CGFloat;
        //Instead, get the keyboard height and calculate the message field height
        let orientation:UIDeviceOrientation = UIDevice.current.orientation;
        if (UIDeviceOrientationIsLandscape(orientation))
        {
          messageHeight = 68.0;
        }
        else {
          
          if (HSAppearance.isTall()) {
            messageHeight = 249.0;
          }else{
            messageHeight = 155.0 + 44.0;
          }
        }
        // return self.view.bounds.size.height - 88.0;
        return messageHeight;
        
      }
    }
    
    return 0.0
  }
  
}
