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
  
  func simpleDescription() -> String {
    switch self {
    case .NYPL:
      return "New York Public Library"
    case .Brooklyn:
      return "Brooklyn Public Library"
    case .Magic:
      return "Instant Classics"
    }
  }
  
  func logo() -> UIImage? {
    switch self {
    case .NYPL:
      return UIImage(named: "LibraryLogoNYPL")
    case .Brooklyn:
      return UIImage(named: "LibraryLogoBrooklyn")
    case .Magic:
      return UIImage(named: "LibraryLogoMagic2")
    }
  }
}

class Accounts: NSObject
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
        for account in array
        {
          accounts.append(Account(json: account))
        }
      }
    } catch {
      // Handle Error
    }
    
    self.accounts = accounts
  }
  
  @objc func account(id:Int) -> Account {
    var account = Account()
    for acc in accounts {
      if acc.id == id
      {
        account = acc
      }
    }
    return account
  }
}

class Account:NSObject
{
  let id:Int?
  let pathComponent:String?
  let name:String?
  let logo:String?
  let needsAuth:Bool?
  let catalogUrl:String?
  let mainColor:String?
  
  override init()
  {
    id = Int()
    name = String()
    pathComponent = String()
    logo = String()
    needsAuth = Bool()
    catalogUrl = String()
    mainColor = String()
  }
  
  init(json: [String: AnyObject])
  {
    name = json["name"] as? String
    id = json["id"] as? Int
    pathComponent = json["pathComponent"] as? String
    logo = json["logo"] as? String
    needsAuth = json["needsAuth"] as? Bool
    catalogUrl = json["catalogUrl"] as? String
    mainColor = json["mainColor"] as? String
  }
}


