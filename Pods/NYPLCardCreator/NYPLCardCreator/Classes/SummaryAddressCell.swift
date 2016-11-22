import UIKit

/// A subclass of `UITableViewCell` that displays an address and section title within its content view.
final class SummaryAddressCell: UITableViewCell {
  
  let sectionLabel, street1Label, street2Label, cityLabel, regionLabel, zipLabel: UILabel
  
  fileprivate var addressValue: Address?
  var address: Address? {
    get {
      return self.addressValue
    }
    set {
      self.addressValue = newValue
      self.street1Label.text = newValue?.street1
      self.street2Label.text = newValue?.street2
      self.cityLabel.text = newValue?.city
      if let region = newValue?.region {
        self.regionLabel.text = ", \(region) "
      }
      self.zipLabel.text = newValue?.zip
    }
  }
  
  init(section: String, style: UITableViewCellStyle, reuseIdentifier: String?) {
    self.sectionLabel = UILabel()
    self.street1Label = UILabel()
    self.street2Label = UILabel()
    self.cityLabel = UILabel()
    self.regionLabel = UILabel()
    self.zipLabel = UILabel()
    
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    
    self.contentView.backgroundColor = UIColor.clear
    
    //Style labels
    self.sectionLabel.text = section
    self.sectionLabel.text  = self.sectionLabel.text?.uppercased()
    self.sectionLabel.textColor = UIColor.darkGray
    self.sectionLabel.font = UIFont(name: "AvenirNext-Regular", size: 14)
    
    self.contentView.addSubview(self.sectionLabel)
    self.sectionLabel.autoPinEdge(toSuperviewMargin: .left)
    self.sectionLabel.autoPinEdge(toSuperviewMargin: .right)
    
    //Top section
    if (section == "Home Address") {
    self.sectionLabel.autoPinEdge(toSuperviewEdge: .top, withInset: 2)
    } else {
      self.sectionLabel.autoPinEdge(toSuperviewEdge: .top, withInset: 12)
    }
    
    self.contentView.addSubview(self.street1Label)
    self.street1Label.autoPinEdge(toSuperviewMargin: .left)
    self.street1Label.autoPinEdge(toSuperviewMargin: .right)
    self.street1Label.autoPinEdge(.top, to: .bottom, of: self.sectionLabel, withOffset: 2)
    
    self.contentView.addSubview(self.street2Label)
    self.street2Label.autoPinEdge(toSuperviewMargin: .left)
    self.street2Label.autoPinEdge(toSuperviewMargin: .right)
    self.street2Label.autoPinEdge(.top, to: .bottom, of: self.street1Label)
    
    self.contentView.addSubview(self.cityLabel)
    self.contentView.addSubview(self.regionLabel)
    self.contentView.addSubview(self.zipLabel)
    
    self.cityLabel.autoPinEdge(toSuperviewMargin: .left)
    self.cityLabel.autoPinEdge(.top, to: .bottom, of: self.street2Label)
    self.cityLabel.autoPinEdge(.right, to: .left, of: self.regionLabel)
    self.cityLabel.autoPinEdge(toSuperviewEdge: .bottom)
    
    self.regionLabel.autoPinEdge(.top, to: .bottom, of: self.street2Label)
    self.regionLabel.autoPinEdge(toSuperviewEdge: .bottom)
    
    self.zipLabel.autoPinEdge(.left, to: .right, of: self.regionLabel)
    self.zipLabel.autoPinEdge(.top, to: .bottom, of: self.street2Label)
    self.zipLabel.autoPinEdge(toSuperviewEdge: .bottom)
  }
  
  @available(*, unavailable)
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
