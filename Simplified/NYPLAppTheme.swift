@objcMembers final class NYPLAppTheme: NSObject {

  private enum NYPLAppThemeColor: String {
    case red
    case pink
    case purple
    case deepPurple = "lightpurple"
    case indigo
    case blue
    case lightBlue = "lightblue"
    case cyan
    case teal
    case green
    case amber
    case orange
    case deepOrange = "lightorange"
    case brown
    case grey
    case blueGrey = "bluegrey"
    case black
  }

  class func themeColorFromString(name: String) -> UIColor {
    if let theme = NYPLAppThemeColor(rawValue: name.lowercased()) {
      return colorFromHex(hex(theme))
    } else {
      Log.error(#file, "Given theme color is not supported: \(name)")
      return .black
    }
  }

  private class func colorFromHex(_ hex: Int) -> UIColor {
    return UIColor(red: CGFloat((hex & 0xFF0000) >> 16)/255,
                   green: CGFloat((hex & 0xFF00) >> 8)/255,
                   blue: CGFloat(hex & 0xFF)/255,
                   alpha: 1.0)
  }

  // Currently using 'primary-dark' variant of
  // Android Color Palette 500 series. https://material.io/tools/color/
  // An updated palette should update hex, but leave the enum values.
  private class func hex(_ theme: NYPLAppThemeColor) -> Int {
    switch(theme) {
    case .red:
      return 0xb9000d
    case .pink:
      return 0xb0003a
    case .purple:
      return 0x6a0080
    case .deepPurple:
      return 0x320b86
    case .indigo:
      return 0x002984
    case .blue:
      return 0x0069c0
    case .lightBlue:
      return 0x007ac1
    case .cyan:
      return 0x008ba3
    case .teal:
      return 0x087f23
    case .green:
      return 0x087f23
    case .amber:
      return 0xc79100
    case .orange:
      return 0xc66900
    case .deepOrange:
      return 0xc41c00
    case .brown:
      return 0x4b2c20
    case .grey:
      return 0x707070
    case .blueGrey:
      return 0x34515e
    case .black:
      return 0x000000
    }
  }
}
