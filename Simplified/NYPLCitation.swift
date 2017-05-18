//
//  NYPLCitation.swift
//  Simplified
//
//  Created by Vui Nguyen on 5/10/17.
//  Copyright © 2017 NYPL Labs. All rights reserved.
//

import Foundation

class NYPLCitation
{
  var book: NYPLBook?
  var publisher: String = ""
  var publicationYear: Int = 1900
  var distributer: String = ""
  var authors: String = ""
  var title: String = ""
  var accessedBy: String = ""
  var currentDate: String = ""
  
  init()
  {
  }
  
  init(book: NYPLBook)
  {
    self.book = book
  }
  
  func APAFormat() -> String
  {
    var APACitation = "Could not Create Citation in APA format"
  
    if (self.book != nil)
    {
      APACitation = "\(getAuthors()) (\(getPublicationYear())). \(getTitle()). \(getPublisher()). \(getDistributor()). \(getAccessedBy())."
    }
    return APACitation
  }
  
  func MLAFormat() -> (fullCitation: String, textToItalicize: String, positionToStartItalics: Int)
  {
    var MLACitation = "Could not Create Citation in MLA format"
    var charactersToTitle = 0
    
    if (self.book != nil)
    {
      MLACitation = ""
      MLACitation = "\(getAuthors()). "
      charactersToTitle = MLACitation.characters.count
      MLACitation += "\(getTitle()). \(getPublisher()). \(getDistributor()). \(getAccessedBy()), \(getCurrentDate())."
    }
    return (MLACitation, getTitle(), charactersToTitle)
  }
  
  func ChicagoFormat() -> (fullCitation: String, textToItalicize: String, positionToStartItalics: Int)
  {
    var ChicagoCitation = "Could not Create Citation in Chicago format"
    var charactersToTitle = 0
    if (self.book != nil)
    {
      ChicagoCitation = ""
      ChicagoCitation = "\(getAuthors()). "
      charactersToTitle = ChicagoCitation.characters.count
      ChicagoCitation += "\(getTitle()). \(getPublicationYear()). \(getPublisher()). \(getDistributor()). \(getAccessedBy())."
      
    }
    return (ChicagoCitation, getTitle(), charactersToTitle)
  }
  
  private func getPublicationYear() -> Int
  {
    let calendar = Calendar.current
    publicationYear = calendar.component(.year, from: (book?.published)!)
    return publicationYear
  }
  
  private func getCurrentDate() -> String
  {
    if (currentDate != "")
    {
      return currentDate
    }
    
    let date = Date()
    let calendar = Calendar.current
    let formatter = DateFormatter()
    let months = formatter.shortMonthSymbols
    let monthName = months?[calendar.component(.month, from: date) - 1]
    currentDate = "\(calendar.component(.day, from: date)) \(monthName ?? "January") \(calendar.component(.year, from: date))"
    return currentDate
  }
  
  private func getAuthors() -> String
  {
    if (authors != "")
    {
      return authors
    }

    if let nonNilAuthors = book?.authors
    {
      authors = nonNilAuthors
    }
    return authors
  }
  
  private func getTitle() -> String
  {
    if (title != "")
    {
      return title
    }
    
    if let nonNilTitle = book?.title
    {
      title = "\(nonNilTitle)"
    }
    return title
  }
  
  private func getPublisher() -> String
  {
    if (publisher != "")
    {
      return publisher
    }
    
    if let nonNilPublisher = book?.publisher
    {
      publisher = "Published by \(nonNilPublisher)"
    }
    return publisher
  } // end getPublisher
  
  private func getDistributor() -> String
  {
    if (distributer != "")
    {
      return distributer
    }
    
    if let nonNilDistributor = book?.distributor
    {
      distributer = "Distributed by \(nonNilDistributor)"
    }
    return distributer
  } // end getDistributor
  
  private func getAccessedBy() -> String
  {
    if (accessedBy != "")
    {
      return accessedBy
    }
    
    accessedBy = "Accessed by SimplyE application http://www.librarysimplified.org"
    return accessedBy
  }
}
