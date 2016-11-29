//
//  Accounts.swift
//  Simplified
//
//  Created by Aferdita Muriqi on 11/11/16.
//  Copyright © 2016 NYPL Labs. All rights reserved.
//

import Foundation

/// Type of library accounts that can be added by the user
/// to log in with.
@objc enum NYPLUserAccountType: Int {
  case NYPL = 0
  case Brooklyn
  case Magic
  case MagicExtra
}

class AccountsManager: NSObject
{
  var accounts:[Account]
  
  override init()
  {
    var accounts = [Account]()
    let url = NSBundle.mainBundle().URLForResource("Accounts", withExtension: "json")
    let data = NSData(contentsOfURL: url!)
    do {
      let object = try NSJSONSerialization.JSONObjectWithData(data!, options: .AllowFragments)
      if let array = object as? [[String: AnyObject]]
      {
        for dictionary in array
        {
          accounts.append(Account(json: dictionary))
        }
      }
    } catch {
      // Handle Error
    }
    
    self.accounts = accounts
  }
  
  @objc class func initializeFromJson()
  {
    let url = NSBundle.mainBundle().URLForResource("Accounts", withExtension: "json")
    let data = NSData(contentsOfURL: url!)
    do {
      let object = try NSJSONSerialization.JSONObjectWithData(data!, options: .AllowFragments)
      if let array = object as? [[String: AnyObject]]
      {
        for dictionary in array
        {
          let account = Account(json: dictionary)
          
          if (NSUserDefaults.standardUserDefaults().valueForKey(account.pathComponent!) == nil)
          {
            NSUserDefaults.standardUserDefaults().setObject(dictionary, forKey: account.pathComponent!)
          }
          else
          {
            // update
            var dictionary = NSUserDefaults.standardUserDefaults().valueForKey(account.pathComponent!) as! [String: AnyObject]
            dictionary["name"] = account.name
            dictionary["subtitle"] = account.subtitle
            dictionary["logo"] = account.logo
            dictionary["needsAuth"] = account.needsAuth
            dictionary["supportsReservations"] = account.supportsReservations
            dictionary["catalogUrl"] = account.catalogUrl
            dictionary["mainColor"] = account.mainColor
            
            NSUserDefaults.standardUserDefaults().setObject(dictionary, forKey: account.pathComponent!)
            
          }
          
        }
      }
    } catch {
      // Handle Error
    }
    

  }
  
   @objc class func account(id:Int) -> Account {
//    var account = Account()
    
    if let dictionary =  NSUserDefaults.standardUserDefaults().valueForKey("\(id)")
    {
        return Account(json: dictionary as! [String: AnyObject])
    }
    return Account()
  }
}

class Account:NSObject
{
  let id:Int
  let pathComponent:String?
  let name:String?
  let subtitle:String?
  let logo:String?
  let needsAuth:Bool
  let supportsReservations:Bool
  let catalogUrl:String?
  let mainColor:String?
  
  
  
  override init()
  {
    id = Int()
    name = String()
    subtitle = String()
    pathComponent = String()
    logo = String()
    needsAuth = Bool()
    supportsReservations = Bool()
    catalogUrl = String()
    mainColor = String()
  }
  
  init(json: [String: AnyObject])
  {
    name = json["name"] as? String
    subtitle = json["subtitle"] as? String
    id = json["id"] as! Int
    pathComponent = json["pathComponent"] as? String
    logo = json["logo"] as? String
    needsAuth = json["needsAuth"] as! Bool
    supportsReservations = json["supportsReservations"] as! Bool
    catalogUrl = json["catalogUrl"] as? String
    mainColor = json["mainColor"] as? String
  }
}


