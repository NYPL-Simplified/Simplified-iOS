//
//  NYPLSettingsSyncViewController.swift
//  Simplified
//
//  Created by Aferdita Muriqi on 5/4/17.
//  Copyright © 2017 NYPL Labs. All rights reserved.
//

import UIKit

class NYPLSettingsSyncViewController: UITableViewController {
  
  
  var sections = 1;
  var accountType = 0
  var toggle:UISwitch!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.view.backgroundColor = NYPLConfiguration.backgroundColor()
    checkSyncSetting()
    
    let account = AccountsManager.shared.account(self.accountType)
    if account!.syncIsEnabledForThisDevice {
      sections = 2
    }
    
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  
  override func numberOfSections(in tableView: UITableView) -> Int {
    return sections
  }
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    if section == 0 {
      return 1
    }
    else {
      return 2
    }
  }
  
  override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
    if section == 0  {
      return NSLocalizedString("SettingsGlobalSync",
                               comment: "Disclaimer for switch to turn on or off syncing.")
    }
    return NSLocalizedString("SettingsIndividualSync",
                             comment: "Disclaimer for switch to turn on or off syncing.")
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    
    let account = AccountsManager.shared.account(self.accountType)
    
    let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
    toggle = UISwitch(frame: CGRect.zero)
    toggle.isOn = account!.syncIsEnabledForThisDevice
    cell.selectionStyle = .none
    cell.textLabel?.font = UIFont.systemFont(ofSize: 17)
    
    if indexPath.section == 0 {
      cell.accessoryView = toggle;
      cell.contentView.addSubview(toggle)
      toggle.addTarget(self, action: #selector(syncSwitchChanged(sender:)), for: .valueChanged)
      cell.textLabel?.text = NSLocalizedString("SettingsGlobalSyncTitle", comment: "")
    }
    else {
      if (indexPath.row == 0) {
        
        let toggleBookmarks = UISwitch(frame: CGRect.zero)
        cell.accessoryView = toggleBookmarks;
        cell.contentView.addSubview(toggleBookmarks)

        toggleBookmarks.isOn = account!.syncBookmarksIsEnabled
        toggleBookmarks.addTarget(self, action: #selector(syncBookmarksSwitchChanged), for: .valueChanged)
        cell.textLabel?.text = NSLocalizedString("SettingsBookmarkSyncTitle", comment: "")
      }
      else {
        let toggleLastRead = UISwitch(frame: CGRect.zero)
        cell.accessoryView = toggleLastRead;
        cell.contentView.addSubview(toggleLastRead)

        toggleLastRead.isOn = account!.syncLastReadingPositionIsEnabled
        toggleLastRead.addTarget(self, action: #selector(syncLastReadSwitchChanged), for: .valueChanged)
        cell.textLabel?.text = NSLocalizedString("SettingsLastReadSyncTitle", comment: "")
      }
    }
    return cell
  }
  func syncBookmarksSwitchChanged(){
  
    let account = AccountsManager.shared.account(self.accountType)
    account!.syncBookmarksIsEnabled = !account!.syncBookmarksIsEnabled

  }
  func syncLastReadSwitchChanged(){
    
    let account = AccountsManager.shared.account(self.accountType)
    account!.syncLastReadingPositionIsEnabled = !account!.syncLastReadingPositionIsEnabled
  
  }
  func syncSwitchChanged(sender:UISwitch){
    let account = AccountsManager.shared.account(self.accountType)
    
    var title:String!
    var message:String!
    if (account!.syncIsEnabledForThisDevice) {
      title = "Disable Sync?"
      message = "Do not synchronize your bookmarks and last reading position across all of your devices.";
    }
    else {
      title = "Enable Sync?";
      message = "Synchronize your bookmarks and last reading position across all of your devices.";
    }
    
    let alert = NYPLAlertController(title: title, message: message, preferredStyle: .alert)
    if (account!.syncIsEnabledForThisDevice) {
      
      alert.addAction(UIAlertAction(title: "Disable This Device", style: .default, handler: { (action) in
        
        account!.syncIsEnabledForThisDevice = false;
        account!.syncBookmarksIsEnabled = false
        account!.syncLastReadingPositionIsEnabled = false

        self.sections -= 1
        self.tableView.deleteSections(IndexSet([1]), with: .fade)
        self.toggle.isOn = account!.syncIsEnabledForThisDevice;
        
      }))
      alert.addAction(UIAlertAction(title: "Disable All Devices", style: .default, handler: { (action) in
        
        NYPLAnnotations.updateSyncSettings(false)
        account!.syncIsEnabledForAllDevices = false;
        account!.syncIsEnabledForThisDevice = false;
        account!.syncBookmarksIsEnabled = false
        account!.syncLastReadingPositionIsEnabled = false

        self.sections -= 1
        self.tableView.deleteSections(IndexSet([1]), with: .fade)
        self.toggle.isOn = account!.syncIsEnabledForAllDevices;
        
      }))
      
    }
    else {
      alert.addAction(UIAlertAction(title: "Enable Sync", style: .default, handler: { (action) in
        
        NYPLAnnotations.updateSyncSettings(true)
        account!.syncIsEnabledForAllDevices = true;
        account!.syncIsEnabledForThisDevice = true;
        account!.syncBookmarksIsEnabled = true
        account!.syncLastReadingPositionIsEnabled = true

        self.sections += 1
        self.tableView.insertSections(IndexSet([1]), with: .fade)
        self.toggle.isOn = account!.syncIsEnabledForAllDevices;
        
      }))
      
    }
    
    alert.addAction(UIAlertAction(title: "Not Now", style: .cancel, handler: { (action) in
      
      self.tableView.reloadData()
      self.toggle.isOn = account!.syncIsEnabledForThisDevice;
      
    }))
    
    
    NYPLRootTabBarController.shared().safelyPresentViewController(alert, animated: true, completion: nil)
    
    
    
    
    
  }
  
  func checkSyncSetting() {
    
    NYPLAnnotations.getSyncSettings { (initialized, value) in
      
      if (!initialized) {
        
        let account = AccountsManager.shared.account(self.accountType)
        
        let alert = NYPLAlertController(title: "New! SimplyE Sync", message: "Automatically update your bookmarks and last reading position across all of your devices.", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Not Now", style: .default, handler: { (action) in
          
          NYPLAnnotations.updateSyncSettings(false)
          account?.syncIsEnabledForAllDevices = false
          account?.syncIsEnabledForThisDevice = false
          self.tableView.reloadSections(IndexSet([1]), with: .automatic)
          
        }))
        
        alert.addAction(UIAlertAction(title: "Enable Sync", style: .default, handler: { (action) in
          
          NYPLAnnotations.updateSyncSettings(true)
          account?.syncIsEnabledForAllDevices = true
          account?.syncIsEnabledForThisDevice = true
          self.tableView.reloadSections(IndexSet([1]), with: .automatic)
          
        }))
        
        NYPLRootTabBarController.shared().safelyPresentViewController(alert, animated: true, completion: nil)
        
      }
      
    }
  }
  
  
  
  
  
  
}
