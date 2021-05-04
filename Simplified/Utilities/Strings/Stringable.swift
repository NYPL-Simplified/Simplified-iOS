//
//  Stringable.swift
//  Simplified
//
//  Created by Ernest Fan on 2021-05-03.
//  Copyright © 2021 NYPL Labs. All rights reserved.
//

import Foundation

public protocol Stringable {
    static var asString: String { get }
}

public extension Stringable {
    var asString: String {
        return String(describing: type(of: self))
    }

    static var asString: String {
        return String(describing: self)
    }
    
    static var nibName: String {
        return self.asString
    }
    
    static var reuseId: String {
        return self.asString
    }
    
    var nibName: String {
        return self.asString
    }
    
    var reuseId: String {
        return self.asString
    }
}

extension UITableViewCell: Stringable {}
extension UICollectionReusableView: Stringable {}
extension UISearchBar: Stringable{}
