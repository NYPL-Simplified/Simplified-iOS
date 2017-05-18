//
//  NYPLCitationsViewController.swift
//  Simplified
//
//  Created by Vui Nguyen on 5/8/17.
//  Copyright © 2017 NYPL Labs. All rights reserved.
//

import Foundation
import UIKit

class NYPLCitationsViewController: UIViewController
{
  @IBOutlet weak var segmentControl: UISegmentedControl!
  @IBOutlet weak var citationLabel: UILabel!
  
  @IBAction func didSelectSegment(_ sender: Any) {
    Log.info("NYPLCitationsViewController", "Segment selected is \(self.segmentControl.selectedSegmentIndex)")
    
    segmentControlAction()
  }
  
  @IBAction func didTapCancel(_ sender: Any) {
    self.dismiss(animated: true, completion: nil)
  }
  
  @IBAction func didTapShare(_ sender: Any) {
    Log.info("NYPLCitationsViewController", "user tapped share")
    
    var activityItems: [Any] = []
    if let shareText = citationLabel.text {
      activityItems.append(shareText)
    }
    
    let activityViewController = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    activityViewController.popoverPresentationController?.sourceView = self.view // so that iPads won't crash

    // exclude some activity types from the list (optional)
    //activityViewController.excludedActivityTypes = [ UIActivityType.airDrop, UIActivityType.postToFacebook ]

    // present the view controller
    self.present(activityViewController, animated: true, completion: nil)
  }
  
  var book: NYPLBook?
  var citation: NYPLCitation = NYPLCitation()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    if (self.book != nil)
    {
      citation.book = self.book
    }
  
    segmentControlAction()
  }

  func italicizeText(textToItalicize: String, positionToStartItalics: Int) {
    //Log.info("NYPLCitationsViewController", "italicizeText")
    let customString = NSMutableAttributedString(string: citationLabel.text!)
    customString.addAttribute(NSFontAttributeName, value: UIFont.italicSystemFont(ofSize: 17.0), range: NSRange(location: positionToStartItalics, length: textToItalicize.characters.count))
    
    citationLabel.attributedText = customString
  }

  
  func segmentControlAction() {
    switch (self.segmentControl.selectedSegmentIndex) {
    case 0:
      let textValues = citation.ChicagoFormat()
      citationLabel.text = textValues.fullCitation
      italicizeText(textToItalicize: textValues.textToItalicize, positionToStartItalics: textValues.positionToStartItalics)
      break;
    case 1:
      let textValues = citation.MLAFormat()
      citationLabel.text = textValues.fullCitation
      italicizeText(textToItalicize: textValues.textToItalicize, positionToStartItalics: textValues.positionToStartItalics)
      break;
    case 2:
      citationLabel.text = citation.APAFormat()
    default:
      break;
    }
  }
}
