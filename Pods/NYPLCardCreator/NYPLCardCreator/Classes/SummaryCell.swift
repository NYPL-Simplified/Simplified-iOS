import UIKit

/// A subclass of `UITableViewCell` that displays a section title and single line within its content view.
final class SummaryCell: UITableViewCell {
  
  let sectionLabel, cellLabel: UILabel
  
  init(section: String, cellText: String?) {
    self.sectionLabel = UILabel()
    self.cellLabel = UILabel()
    
    super.init(style: .default, reuseIdentifier: nil)
    
    self.contentView.backgroundColor = UIColor.clear
    
    self.sectionLabel.text = section
    self.cellLabel.text = cellText
    
    self.sectionLabel.text  = self.sectionLabel.text?.uppercased()
    self.sectionLabel.textColor = UIColor.darkGray
    self.sectionLabel.font = UIFont(name: "AvenirNext-Regular", size: 14)
    
    self.contentView.addSubview(self.sectionLabel)
    self.sectionLabel.autoPinEdge(toSuperviewMargin: .left)
    self.sectionLabel.autoPinEdge(toSuperviewMargin: .right)
    self.sectionLabel.autoPinEdge(toSuperviewEdge: .top, withInset: 12)
    
    self.contentView.addSubview(self.cellLabel)
    self.cellLabel.autoPinEdge(toSuperviewMargin: .left)
    self.cellLabel.autoPinEdge(toSuperviewMargin: .right)
    self.cellLabel.autoPinEdge(.top, to: .bottom, of: self.sectionLabel, withOffset: 2)
    self.cellLabel.autoPinEdge(toSuperviewEdge: .bottom)
  }
  
  @available(*, unavailable)
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
