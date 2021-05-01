//
//  CALayer+CustomBorder.swift
//  Simplified
//
//  Created by Ernest Fan on 2021-04-27.
//  Copyright © 2021 NYPL Labs. All rights reserved.
//

import Foundation

// Use this to identify the layers added through this class, so it can be removed when needed
private let NYPLSublayerName: String = "NYPLCustomSublayer"

/// Add border to specific side of a view with rounded corners
/// See ref: https://stackoverflow.com/a/30519213

extension CALayer {
    
  enum BorderSide {
    case top
    case right
    case bottom
    case left
    case notRight
    case notLeft
    case notTop
    case notBottom
    case topAndBottom
    case leftAndRight
    case all
  }
  
  enum Corner {
    case topLeft
    case topRight
    case bottomLeft
    case bottomRight
  }
  
  func addBorder(side: BorderSide, thickness: CGFloat, color: CGColor, maskedCorners: CACornerMask? = nil) {
    var topWidth = frame.size.width; var bottomWidth = topWidth
    var leftHeight = frame.size.height; var rightHeight = leftHeight
    
    var topXOffset: CGFloat = 0; var bottomXOffset: CGFloat = 0
    var leftYOffset: CGFloat = 0; var rightYOffset: CGFloat = 0
    
    // Draw the corners and set side offsets
    switch maskedCorners {
    case [.layerMinXMinYCorner, .layerMaxXMinYCorner]: // Top only
      addCorner(.topLeft, thickness: thickness, color: color)
      addCorner(.topRight, thickness: thickness, color: color)
      topWidth -= cornerRadius*2
      leftHeight -= cornerRadius; rightHeight -= cornerRadius
      topXOffset = cornerRadius; leftYOffset = cornerRadius; rightYOffset = cornerRadius
        
    case [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]: // Bottom only
      addCorner(.bottomLeft, thickness: thickness, color: color)
      addCorner(.bottomRight, thickness: thickness, color: color)
      bottomWidth -= cornerRadius*2
      leftHeight -= cornerRadius; rightHeight -= cornerRadius
      bottomXOffset = cornerRadius
        
    case [.layerMinXMinYCorner, .layerMinXMaxYCorner]: // Left only
      addCorner(.topLeft, thickness: thickness, color: color)
      addCorner(.bottomLeft, thickness: thickness, color: color)
      topWidth -= cornerRadius; bottomWidth -= cornerRadius
      leftHeight -= cornerRadius*2
      leftYOffset = cornerRadius; topXOffset = cornerRadius; bottomXOffset = cornerRadius;
        
    case [.layerMaxXMinYCorner, .layerMaxXMaxYCorner]: // Right only
      addCorner(.topRight, thickness: thickness, color: color)
      addCorner(.bottomRight, thickness: thickness, color: color)
      topWidth -= cornerRadius; bottomWidth -= cornerRadius
      rightHeight -= cornerRadius*2
      rightYOffset = cornerRadius
        
    case [.layerMaxXMinYCorner, .layerMaxXMaxYCorner,  // All
          .layerMinXMaxYCorner, .layerMinXMinYCorner]:
      addCorner(.topLeft, thickness: thickness, color: color)
      addCorner(.topRight, thickness: thickness, color: color)
      addCorner(.bottomLeft, thickness: thickness, color: color)
      addCorner(.bottomRight, thickness: thickness, color: color)
      topWidth -= cornerRadius*2; bottomWidth -= cornerRadius*2
      topXOffset = cornerRadius; bottomXOffset = cornerRadius
      leftHeight -= cornerRadius*2; rightHeight -= cornerRadius*2
      leftYOffset = cornerRadius; rightYOffset = cornerRadius
        
    default: break
    }
    
    // Draw the sides
    switch side {
    case .top:
      addLine(x: topXOffset, y: 0, width: topWidth, height: thickness, color: color)
        
    case .right:
      addLine(x: frame.size.width - thickness, y: rightYOffset, width: thickness, height: rightHeight, color: color)
        
    case .bottom:
      addLine(x: bottomXOffset, y: frame.size.height - thickness, width: bottomWidth, height: thickness, color: color)
        
    case .left:
      addLine(x: 0, y: leftYOffset, width: thickness, height: leftHeight, color: color)

    // Multiple Sides
    case .notRight:
      addLine(x: topXOffset, y: 0, width: topWidth, height: thickness, color: color)
      addLine(x: 0, y: leftYOffset, width: thickness, height: leftHeight, color: color)
      addLine(x: bottomXOffset, y: frame.size.height - thickness, width: bottomWidth, height: thickness, color: color)

    case .notLeft:
      addLine(x: topXOffset, y: 0, width: topWidth, height: thickness, color: color)
      addLine(x: frame.size.width - thickness, y: rightYOffset, width: thickness, height: rightHeight, color: color)
      addLine(x: bottomXOffset, y: frame.size.height - thickness, width: bottomWidth, height: thickness, color: color)
      
    case .notTop:
      addLine(x: frame.size.width - thickness, y: rightYOffset, width: thickness, height: rightHeight, color: color)
      addLine(x: bottomXOffset, y: frame.size.height - thickness, width: bottomWidth, height: thickness, color: color)
      addLine(x: 0, y: leftYOffset, width: thickness, height: leftHeight, color: color)
      
    case .notBottom:
      addLine(x: topXOffset, y: 0, width: topWidth, height: thickness, color: color)
      addLine(x: frame.size.width - thickness, y: rightYOffset, width: thickness, height: rightHeight, color: color)
      addLine(x: 0, y: leftYOffset, width: thickness, height: leftHeight, color: color)

    case .topAndBottom:
      addLine(x: topXOffset, y: 0, width: topWidth, height: thickness, color: color)
      addLine(x: bottomXOffset, y: frame.size.height - thickness, width: bottomWidth, height: thickness, color: color)
      
    case .leftAndRight:
      addLine(x: 0, y: leftYOffset, width: thickness, height: leftHeight, color: color)
      addLine(x: frame.size.width - thickness, y: rightYOffset, width: thickness, height: rightHeight, color: color)

    case .all:
      addLine(x: topXOffset, y: 0, width: topWidth, height: thickness, color: color)
      addLine(x: frame.size.width - thickness, y: rightYOffset, width: thickness, height: rightHeight, color: color)
      addLine(x: bottomXOffset, y: frame.size.height - thickness, width: bottomWidth, height: thickness, color: color)
      addLine(x: 0, y: leftYOffset, width: thickness, height: leftHeight, color: color)
    }
  }
  
  func removeCustomBorders() {
    guard let sublayers = sublayers else {
      return
    }
    
    for layer in sublayers {
      if let name = layer.name, name == NYPLSublayerName {
        layer.removeFromSuperlayer()
      }
    }
  }
  
  // MARK: - Helper
  
  private func addLine(x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat, color: CGColor) {
    let border = CALayer()
    border.frame = CGRect(x: x, y: y, width: width, height: height)
    border.backgroundColor = color
    border.name = NYPLSublayerName
    addSublayer(border)
  }
  
  private func addCorner(_ corner: Corner, thickness: CGFloat, color: CGColor) {
    // Set default to top left
    let width = frame.size.width; let height = frame.size.height
    var x = cornerRadius
    var y = cornerRadius
    var startAngle: CGFloat = .pi; var endAngle: CGFloat = .pi*3/2
    
    switch corner {
    case .bottomLeft:
      y = height - cornerRadius
      startAngle = .pi/2; endAngle = .pi
        
    case .bottomRight:
      x = width - cornerRadius
      y = height - cornerRadius
      startAngle = 0; endAngle = .pi/2
        
    case .topRight:
      x = width - cornerRadius
      startAngle = .pi*3/2; endAngle = 0
        
    default: break
    }
    
    let cornerPath = UIBezierPath(arcCenter: CGPoint(x: x, y: y),
                                  radius: cornerRadius - thickness,
                                  startAngle: startAngle,
                                  endAngle: endAngle,
                                  clockwise: true)

    let cornerShape = CAShapeLayer()
    cornerShape.name = NYPLSublayerName
    cornerShape.path = cornerPath.cgPath
    cornerShape.lineWidth = thickness
    cornerShape.strokeColor = color
    cornerShape.fillColor = nil
    addSublayer(cornerShape)
  }
}
