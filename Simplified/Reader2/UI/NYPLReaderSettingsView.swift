//
//  NYPLReaderSettingsView.swift
//  Simplified
//
//  Created by Ernest Fan on 2021-09-01.
//  Copyright © 2021 NYPL Labs. All rights reserved.
//

import Foundation

enum NYPLReaderFontSizeChange {
  case increase
  case decrease
}

protocol NYPLReaderSettingsViewDelegate: class {
  func didSelectBrightness(_ brightness: CGFloat)
  func didSelectColorScheme(_ colorScheme: NYPLReaderSettingsColorScheme)
  func settingsView(_ view: NYPLReaderSettingsView,
                    didChangeFontSize change: NYPLReaderFontSizeChange) -> NYPLReaderSettingsFontSize
  func didSelectFontFace(_ fontFace: NYPLReaderSettingsFontFace)
  func didChangePublisherDefaults(_ isEnabled: Bool)
}

class NYPLReaderSettingsView: UIView {
  private let rowHeight: CGFloat = 60.0
  private var selectedFontBottomBorderLeadingConstraint: NSLayoutConstraint?
  private var selectedFontBottomBorderWidthConstraint: NSLayoutConstraint?
  
  weak var delegate: NYPLReaderSettingsViewDelegate?
  
  // Settings
  var colorScheme: NYPLReaderSettingsColorScheme = .whiteOnBlack {
    didSet {
      updateUIColorScheme()
      updateFontFaceButtons()
    }
  }
  
  var fontSize: NYPLReaderSettingsFontSize = .smallest {
    didSet {
      updateFontSizeButtons()
    }
  }
  
  var fontFace: NYPLReaderSettingsFontFace = .sans {
    didSet {
      publisherDefault = false
    }
  }
  
  // Calling the delegate function here instead of didSelectPublisherDefault
  // because publisher default needs to be off when any other fonts being selected
  var publisherDefault: Bool = false {
    didSet {
      delegate?.didChangePublisherDefaults(publisherDefault)
    }
  }
  
  // MARK: - Init / Setup
  
  init(width: CGFloat,
       colorScheme: NYPLReaderSettingsColorScheme,
       fontSize: NYPLReaderSettingsFontSize,
       fontFace: NYPLReaderSettingsFontFace,
       publisherDefault: Bool) {
    super.init(frame: .zero)
    setupUI(width: width)
    
    self.colorScheme = colorScheme
    self.fontFace = fontFace
    self.fontSize = fontSize
    self.publisherDefault = publisherDefault
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  deinit {
    NotificationCenter.default.removeObserver(self, name: UIScreen.brightnessDidChangeNotification, object: nil)
  }
  
  private func setupUI(width: CGFloat) {
    autoSetDimension(.width, toSize: width)
    
    let topPadding: CGFloat = 16
    let padding: CGFloat = 10
    
    backgroundColor = NYPLConfiguration.primaryBackgroundColor
    
    let partialHorizontalLine = newHorizontalLine()
    partialHorizontalLine.addSubview(selectedFontBottomBorder)
    selectedFontBottomBorder.autoPinEdge(toSuperviewEdge: .top)
    selectedFontBottomBorder.autoPinEdge(toSuperviewEdge: .bottom)
    selectedFontBottomBorderWidthConstraint = selectedFontBottomBorder.autoSetDimension(.width, toSize: (width - padding * 2) / 4)
    selectedFontBottomBorderLeadingConstraint = selectedFontBottomBorder.autoConstrainAttribute(.leading, to: .leading, of: partialHorizontalLine)

    let stackView = UIStackView(arrangedSubviews: [fontFaceStackView,
                                                   partialHorizontalLine,
                                                   fontDescriptionView,
                                                   newHorizontalLine(),
                                                   colorSchemeStackView,
                                                   newHorizontalLine(),
                                                   fontSizeStackView,
                                                   newHorizontalLine(),
                                                   brightnessStackView])
    stackView.axis = .vertical
    stackView.alignment = .fill
    stackView.distribution = .fillProportionally
    addSubview(stackView)
    stackView.autoPinEdgesToSuperviewEdges(with: .init(top: topPadding, left: padding, bottom: padding, right: padding))
  }
  
  // MARK: UI Update
  
  func updateUI() {
    updateUIColorScheme()
    updateSelectedFontDescription()
    updateFontFaceButtons()
    updateFontSizeButtons()
  }
  
  private func updateSelectedFontDescription() {
    if publisherDefault {
      fontTitleLabel.text = NSLocalizedString("Publisher's Default", comment: "Publisher's default description title")
      fontDescriptionLabel.text = NSLocalizedString("Show the publisher-specified fonts and layout choices in this ebook", comment: "Publisher's default description")
      return
    }
    
    var description: String
    switch fontFace {
    case .sans:
      description = NSLocalizedString("Sans", comment: "Font name")
      break
    case .serif:
      description = NSLocalizedString("Serif", comment: "Font name")
      break
    case .openDyslexic:
      description = NSLocalizedString("Open Dyslexic", comment: "Font name")
      break
    }
    
    fontTitleLabel.text = NSLocalizedString("Special Font", comment: "Font description title")
    fontDescriptionLabel.text = description
  }
  
  private func updateUIColorScheme() {
    var backgroundColor: UIColor
    var foregroundColor: UIColor
    
    switch colorScheme {
    case .blackOnSepia:
      blackOnSepiaButton.isEnabled = false
      blackOnWhiteButton.isEnabled = true
      whiteOnBlackButton.isEnabled = true
      backgroundColor = NYPLConfiguration.readerBackgroundSepiaColor()
      foregroundColor = .black
      break
    case .blackOnWhite:
      blackOnSepiaButton.isEnabled = true
      blackOnWhiteButton.isEnabled = false
      whiteOnBlackButton.isEnabled = true
      backgroundColor = NYPLConfiguration.readerBackgroundColor()
      foregroundColor = .black
      break
    case .whiteOnBlack:
      blackOnSepiaButton.isEnabled = true
      blackOnWhiteButton.isEnabled = true
      whiteOnBlackButton.isEnabled = false
      backgroundColor = NYPLConfiguration.readerBackgroundDarkColor()
      foregroundColor = .white
      break
    }
    
    self.backgroundColor = backgroundColor
  
    // Font Face Buttons
    for button in [sansButton, serifButton, openDyslexicButton] {
      updateAttributedTitle(for: button,
                            title: NSLocalizedString("AlphabetFontType", comment: "A title for presenting the desired font"),
                            normalStateColor: foregroundColor,
                            disabledStateColor: foregroundColor)
      button.backgroundColor = backgroundColor
    }
    
    updateAttributedTitle(for: publisherDefaultButton,
                          title: NSLocalizedString("Pub", comment: "A title for publisher's default font selection"),
                          normalStateColor: foregroundColor,
                          disabledStateColor: foregroundColor)
    publisherDefaultButton.backgroundColor = backgroundColor
    
    // Font Description Label
    
    fontTitleLabel.textColor = foregroundColor
    fontDescriptionLabel.textColor = foregroundColor
    fontDescriptionView.backgroundColor = backgroundColor
    
    // Color Scheme buttons
    
    for button in [blackOnSepiaButton, blackOnWhiteButton] {
      updateAttributedTitle(for: button,
                            title: NSLocalizedString("AlphabetFontStyle", comment: "A title for presenting the desired color scheme"),
                            normalStateColor: .black,
                            disabledStateColor: .black)
    }
    
    updateAttributedTitle(for: whiteOnBlackButton,
                          title: NSLocalizedString("AlphabetFontStyle", comment: "A title for presenting the desired color scheme"),
                          normalStateColor: .white,
                          disabledStateColor: .white)
    
    // Font Size buttons
    
    let fontSizeAttributedTitle = NSAttributedString(string: "A",
                                                     attributes: [NSAttributedString.Key.foregroundColor: foregroundColor])
    
    decreaseFontSizeButton.backgroundColor = backgroundColor
    decreaseFontSizeButton.setAttributedTitle(fontSizeAttributedTitle, for: .normal)
    
    increaseFontSizeButton.backgroundColor = backgroundColor
    increaseFontSizeButton.setAttributedTitle(fontSizeAttributedTitle, for: .normal)
    
    // Brightness Slider
    
    self.increaseBrightnessImageView.tintColor = foregroundColor
    self.decreaseBrightnessImageView.tintColor = foregroundColor
  }
  
  private func updateAttributedTitle(for button: UIButton,
                                     title: String,
                                     normalStateColor: UIColor,
                                     disabledStateColor: UIColor) {
    let normalStateAttributes: [NSAttributedString.Key: Any] = [NSAttributedString.Key.underlineStyle: 0,
                                                              NSAttributedString.Key.foregroundColor: normalStateColor]
    let disabledStateAttributes: [NSAttributedString.Key: Any] = [NSAttributedString.Key.underlineStyle: 1,
                                                              NSAttributedString.Key.foregroundColor: disabledStateColor]
    
    let attributedTitleNormal = NSAttributedString(string: title, attributes: normalStateAttributes)
    
    let attributedTitleDisabled = NSAttributedString(string: title, attributes: disabledStateAttributes)
    
    button.setAttributedTitle(attributedTitleNormal, for: .normal)
    
    button.setAttributedTitle(attributedTitleDisabled, for: .disabled)
  }
  
  private func updateFontFaceButtons() {
    if publisherDefault {
      sansButton.isEnabled = true
      serifButton.isEnabled = true
      openDyslexicButton.isEnabled = true
      publisherDefaultButton.isEnabled = false
    } else {
      publisherDefaultButton.isEnabled = true
      switch fontFace {
      case .sans:
        sansButton.isEnabled = false
        serifButton.isEnabled = true
        openDyslexicButton.isEnabled = true
        break
      case .serif:
        sansButton.isEnabled = true
        serifButton.isEnabled = false
        openDyslexicButton.isEnabled = true
        break
      case .openDyslexic:
        sansButton.isEnabled = true
        serifButton.isEnabled = true
        openDyslexicButton.isEnabled = false
        break
      }
    }
    
    switch colorScheme {
    case .blackOnSepia:
      selectedFontBottomBorder.backgroundColor = NYPLConfiguration.readerBackgroundSepiaColor()
      break
    case .blackOnWhite:
      selectedFontBottomBorder.backgroundColor = NYPLConfiguration.readerBackgroundColor()
      break
    case .whiteOnBlack:
      selectedFontBottomBorder.backgroundColor = NYPLConfiguration.readerBackgroundDarkColor()
      break
    }
    
    // Update bottom border of selected font face button
    guard let leadingConstraint = selectedFontBottomBorderLeadingConstraint,
          let widthConstraint = selectedFontBottomBorderWidthConstraint else {
      Log.debug(#function, "Constraints of selected font bottom border not found")
      return
    }
    
    if publisherDefault {
      leadingConstraint.constant = publisherDefaultButton.frame.origin.x
      widthConstraint.constant = publisherDefaultButton.frame.size.width
      return
    }
    
    switch fontFace {
    case .sans:
      leadingConstraint.constant = sansButton.frame.origin.x
      widthConstraint.constant = sansButton.frame.size.width
      break
    case .serif:
      leadingConstraint.constant = serifButton.frame.origin.x
      widthConstraint.constant = serifButton.frame.size.width
      break
    case .openDyslexic:
      leadingConstraint.constant = openDyslexicButton.frame.origin.x
      widthConstraint.constant = openDyslexicButton.frame.size.width
      break
    }
  }
  
  private func updateFontSizeButtons() {
    switch fontSize {
    case .smallest:
      decreaseFontSizeButton.isEnabled = false
      increaseFontSizeButton.isEnabled = true
      break
    case .xxxLarge:
      decreaseFontSizeButton.isEnabled = true
      increaseFontSizeButton.isEnabled = false
      break
    default:
      decreaseFontSizeButton.isEnabled = true
      increaseFontSizeButton.isEnabled = true
      break
    }
  }
  
  // MARK: - Button Actions
  
  @objc private func didSelectSans() {
    fontFace = .sans
    
    delegate?.didSelectFontFace(.sans)
    
    updateSelectedFontDescription()
    updateFontFaceButtons()
  }
  
  @objc private func didSelectSerif() {
    fontFace = .serif
    
    delegate?.didSelectFontFace(.serif)
    
    updateSelectedFontDescription()
    updateFontFaceButtons()
  }
  
  @objc private func didSelectOpenDyslexic() {
    fontFace = .openDyslexic
    
    delegate?.didSelectFontFace(.openDyslexic)
    
    updateSelectedFontDescription()
    updateFontFaceButtons()
  }
  
  @objc private func didSelectPublisherDefault() {
    publisherDefault = true
    
    updateSelectedFontDescription()
    updateFontFaceButtons()
  }
  
  @objc private func didSelectWhiteOnBlack() {
    colorScheme = .whiteOnBlack
    
    delegate?.didSelectColorScheme(.whiteOnBlack)
  }
  
  @objc private func didSelectBlackOnWhite() {
    colorScheme = .blackOnWhite
    
    delegate?.didSelectColorScheme(.blackOnWhite)
  }
  
  @objc private func didSelectBlackOnSepia() {
    colorScheme = .blackOnSepia
    
    delegate?.didSelectColorScheme(.blackOnSepia)
  }
  
  @objc private func didSelectIncrease() {
    guard fontSize != NYPLReaderSettingsFontSize.xxxLarge else {
      Log.debug(#function, "Ignoring attempt to set font size above the max.")
      return
    }
    
    if let delegate = self.delegate {
      fontSize = delegate.settingsView(self, didChangeFontSize: .increase)
    }
  }
  
  @objc private func didSelectDecrease() {
    guard fontSize != NYPLReaderSettingsFontSize.smallest else {
      Log.debug(#function, "Ignoring attempt to set font size below the minimum.")
      return
    }
    
    if let delegate = self.delegate {
      fontSize = delegate.settingsView(self, didChangeFontSize: .decrease)
    }
  }
  
  @objc private func didChangeBrightness() {
    delegate?.didSelectBrightness(CGFloat(brightnessSlider.value))
  }
  
  @objc private func didChangeSystemBrightness(notification: Notification) {
    if let screen = notification.object as? UIScreen {
      brightnessSlider.value = Float(screen.brightness)
    }
  }
  
  // MARK: - UI Properties
  
  private lazy var fontFaceStackView: UIStackView = {
    let stackView = UIStackView(arrangedSubviews: [sansButton,
                                                   serifButton,
                                                   openDyslexicButton,
                                                   publisherDefaultButton])
    stackView.alignment = .fill
    stackView.distribution = .fillEqually
    stackView.axis = .horizontal
    stackView.autoSetDimension(.height, toSize: rowHeight)
    stackView.backgroundColor = .lightGray
    stackView.spacing = 1
    return stackView
  }()
  
  private lazy var fontDescriptionView: UIView = {
    let view = UIView()
    view.addSubview(fontTitleLabel)
    view.addSubview(fontDescriptionLabel)
    fontTitleLabel.autoPinEdgesToSuperviewEdges(with: .init(top: 10, left: 5, bottom: 0, right: 5),
                                                excludingEdge: .bottom)
    fontDescriptionLabel.autoPinEdgesToSuperviewEdges(with: .init(top: 0, left: 5, bottom: 10, right: 5),
                                                      excludingEdge: .top)
    fontTitleLabel.autoPinEdge(.bottom, to: .top, of: fontDescriptionLabel, withOffset: -5)
    return view
  }()
  
  private lazy var colorSchemeStackView: UIStackView = {
    let stackView = UIStackView(arrangedSubviews: [whiteOnBlackButton,
                                                   blackOnSepiaButton,
                                                   blackOnWhiteButton])
    stackView.alignment = .fill
    stackView.distribution = .fillEqually
    stackView.axis = .horizontal
    stackView.autoSetDimension(.height, toSize: rowHeight)
    stackView.backgroundColor = .lightGray
    stackView.spacing = 1
    return stackView
  }()
  
  private lazy var fontSizeStackView: UIStackView = {
    let stackView = UIStackView(arrangedSubviews: [decreaseFontSizeButton,
                                                   increaseFontSizeButton])
    stackView.alignment = .fill
    stackView.distribution = .fillEqually
    stackView.axis = .horizontal
    stackView.autoSetDimension(.height, toSize: rowHeight)
    stackView.backgroundColor = .lightGray
    stackView.spacing = 1
    return stackView
  }()
  
  private lazy var brightnessStackView: UIStackView = {
    let stackView = UIStackView(arrangedSubviews: [decreaseBrightnessImageView,
                                                   brightnessSlider,
                                                   increaseBrightnessImageView])
    stackView.alignment = .center
    stackView.distribution = .fillProportionally
    stackView.axis = .horizontal
    stackView.autoSetDimension(.height, toSize: rowHeight)
    stackView.spacing = 10
    return stackView
  }()
  
  // Font Face Buttons
  
  private lazy var sansButton: UIButton = {
    let title = NSLocalizedString("AlphabetFontType", comment: "A title for presenting the desired font")
    
    let button = newCustomButton(title: title,
                                 titleColor: .black,
                                 fontName: "Helvetica",
                                 fontSize: 22,
                                 normalStateAttributes: [NSAttributedString.Key.underlineStyle: 0],
                                 disabledStateAttributes: [NSAttributedString.Key.underlineStyle: 1])
    button.accessibilityLabel = NSLocalizedString("SansFont", comment: "Accessible label for the font")
    button.addTarget(self, action: #selector(didSelectSans), for: .touchUpInside)
    return button
  }()
  
  private lazy var serifButton: UIButton = {
    let title = NSLocalizedString("AlphabetFontType", comment: "A title for presenting the desired font")
    
    let button = newCustomButton(title: title,
                                 titleColor: .black,
                                 fontName: "Georgia",
                                 fontSize: 22,
                                 normalStateAttributes: [NSAttributedString.Key.underlineStyle: 0],
                                 disabledStateAttributes: [NSAttributedString.Key.underlineStyle: 1])
    button.accessibilityLabel = NSLocalizedString("SerifFont", comment: "Accessible label for the font")
    button.addTarget(self, action: #selector(didSelectSerif), for: .touchUpInside)
    return button
  }()
  
  private lazy var openDyslexicButton: UIButton = {
    let title = NSLocalizedString("AlphabetFontType", comment: "A title for presenting the desired font")
    
    let button = newCustomButton(title: title,
                                 titleColor: .black,
                                 fontName: "OpenDyslexic3",
                                 fontSize: 18,
                                 normalStateAttributes: [NSAttributedString.Key.underlineStyle: 0],
                                 disabledStateAttributes: [NSAttributedString.Key.underlineStyle: 1])
    button.accessibilityLabel = NSLocalizedString("OpenDyslexicFont", comment: "Accessible label for the font")
    button.addTarget(self, action: #selector(didSelectOpenDyslexic), for: .touchUpInside)
    return button
  }()
  
  private lazy var publisherDefaultButton: UIButton = {
    let title = NSLocalizedString("Pub", comment: "A title for publisher's default font selection")
    let button = newCustomButton(title: title,
                                 titleColor: .black,
                                 fontName: "Helvetica",
                                 fontSize: 22,
                                 normalStateAttributes: [NSAttributedString.Key.underlineStyle: 0],
                                 disabledStateAttributes: [NSAttributedString.Key.underlineStyle: 1])
    button.accessibilityLabel = NSLocalizedString("Publisher's Default", comment: "Accessible label for the font")
    button.addTarget(self, action: #selector(didSelectPublisherDefault), for: .touchUpInside)
    return button
  }()
  
  // This view hides the border between the selected font button and font description
  private lazy var selectedFontBottomBorder: UIView = {
    let view = UIView()
    view.backgroundColor = NYPLConfiguration.primaryBackgroundColor
    return view
  }()
  
  private lazy var fontTitleLabel: UILabel = {
    let label = UILabel()
    label.textAlignment = .left
    label.font = .systemFont(ofSize: 22, weight: .medium)
    label.text = NSLocalizedString("Special Font", comment: "Font description title")
    label.numberOfLines = 1
    label.setContentHuggingPriority(.required, for: .vertical)
    return label
  }()
  
  private lazy var fontDescriptionLabel: UILabel = {
    let label = UILabel()
    label.textAlignment = .left
    label.font = .systemFont(ofSize: 16)
    label.numberOfLines = 0
    // NYPLReaderSettingsView is dynamic height when being initialized,
    // so we want to initialize this label with the possible largest amount of text
    // to ensure there is enough room.
    label.text = NSLocalizedString("Show the publisher-specified fonts and layout choices in this ebook", comment: "Publisher's default description")
    label.setContentHuggingPriority(.fittingSizeLevel, for: .vertical)
    return label
  }()
  
  // Color Scheme Buttons
  
  private lazy var blackOnSepiaButton: UIButton = {
    let title = NSLocalizedString("AlphabetFontStyle", comment: "A title for presenting the desired color scheme")
    
    let button = newCustomButton(title: title,
                                 fontSize: 18,
                                 normalStateAttributes: [NSAttributedString.Key.underlineStyle: 0,
                                                         NSAttributedString.Key.foregroundColor: UIColor.black],
                                 disabledStateAttributes: [NSAttributedString.Key.underlineStyle: 1,
                                                           NSAttributedString.Key.foregroundColor: NYPLConfiguration.mainColor()])
    button.backgroundColor = NYPLConfiguration.readerBackgroundSepiaColor()
    button.accessibilityLabel = NSLocalizedString("BlackOnSepiaText", comment: "Accessible label for the color scheme")
    button.addTarget(self, action: #selector(didSelectBlackOnSepia), for: .touchUpInside)
    return button
  }()
  
  private lazy var blackOnWhiteButton: UIButton = {
    let title = NSLocalizedString("AlphabetFontStyle", comment: "A title for presenting the desired color scheme")
    
    let button = newCustomButton(title: title,
                                 fontSize: 18,
                                 normalStateAttributes: [NSAttributedString.Key.underlineStyle: 0,
                                                         NSAttributedString.Key.foregroundColor: UIColor.black],
                                 disabledStateAttributes: [NSAttributedString.Key.underlineStyle: 1,
                                                           NSAttributedString.Key.foregroundColor: NYPLConfiguration.mainColor()])
    button.backgroundColor = NYPLConfiguration.readerBackgroundColor()
    button.accessibilityLabel = NSLocalizedString("BlackOnWhiteText", comment: "Accessible label for the color scheme")
    button.addTarget(self, action: #selector(didSelectBlackOnWhite), for: .touchUpInside)
    return button
  }()
  
  private lazy var whiteOnBlackButton: UIButton = {
    let title = NSLocalizedString("AlphabetFontStyle", comment: "A title for presenting the desired color scheme")
    
    let button = newCustomButton(title: title,
                                 fontSize: 18,
                                 normalStateAttributes: [NSAttributedString.Key.underlineStyle: 0,
                                                         NSAttributedString.Key.foregroundColor: UIColor.white],
                                 disabledStateAttributes: [NSAttributedString.Key.underlineStyle: 1,
                                                           NSAttributedString.Key.foregroundColor: UIColor.white])
    button.backgroundColor = NYPLConfiguration.readerBackgroundDarkColor()
    button.accessibilityLabel = NSLocalizedString("WhiteOnBlackText", comment: "Accessible label for the color scheme")
    button.addTarget(self, action: #selector(didSelectWhiteOnBlack), for: .touchUpInside)
    return button
  }()
  
  // Font Size Buttons
  
  private lazy var decreaseFontSizeButton: UIButton = {
    let button = newCustomButton(title: "A",
                                 fontSize: 16,
                                 normalStateAttributes: [NSAttributedString.Key.foregroundColor: UIColor.black],
                                 disabledStateAttributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
    button.accessibilityLabel = NSLocalizedString("DecreaseFontSize", comment: "Accessible label for font size decreasing")
    button.addTarget(self, action: #selector(didSelectDecrease), for: .touchUpInside)
    return button
  }()
  
  private lazy var increaseFontSizeButton: UIButton = {
    let button = newCustomButton(title: "A",
                                 fontSize: 24,
                                 normalStateAttributes: [NSAttributedString.Key.foregroundColor: UIColor.black],
                                 disabledStateAttributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
    button.accessibilityLabel = NSLocalizedString("IncreaseFontSize", comment: "Accessible label for font size increasing")
    button.addTarget(self, action: #selector(didSelectIncrease), for: .touchUpInside)
    return button
  }()
  
  // Brightness Slider
  
  private lazy var brightnessSlider: UISlider = {
    let slider = UISlider()
    slider.value = Float(UIScreen.main.brightness)
    slider.accessibilityLabel = NSLocalizedString("BrightnessSlider", comment: "Accessible label for brightness setting")
    slider.addTarget(self, action: #selector(didChangeBrightness), for: .valueChanged)
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(didChangeSystemBrightness(notification:)),
                                           name: UIScreen.brightnessDidChangeNotification,
                                           object: nil)
    return slider
  }()
  
  private lazy var decreaseBrightnessImageView: UIImageView = {
    let image = UIImage(named: "BrightnessLow")?.withRenderingMode(.alwaysTemplate)
    let imageView = UIImageView(image: image)
    imageView.autoSetDimensions(to: .init(width: 20, height: 20))
    return imageView
  }()
  
  private lazy var increaseBrightnessImageView: UIImageView = {
    let image = UIImage(named: "BrightnessHigh")?.withRenderingMode(.alwaysTemplate)
    let imageView = UIImageView(image: image)
    imageView.autoSetDimensions(to: .init(width: 30, height: 30))
    return imageView
  }()
  
  // MARK: UI Helper
  
  /// Create and return an instance of UIButton with the given attributes
  /// - Parameter title: Text to be shown on the button
  /// - Parameter titleColor: Color for the button's title, optional
  /// - Parameter fontName: Font face for the button's title. nil means to use system font
  /// - Parameter fontSize: Font size for the button's title.
  /// - Parameter normalStateAttributes: Attributes to be set for the button when it's in normal state, optional
  /// - Parameter disabledStateAttributes: Attributes to be set for the button when it's in disabled state, optional
  private func newCustomButton(title: String,
                               titleColor: UIColor? = nil,
                               fontName: String? = nil,
                               fontSize: CGFloat,
                               normalStateAttributes: [NSAttributedString.Key: Any]? = nil,
                               disabledStateAttributes: [NSAttributedString.Key: Any]? = nil) -> UIButton {
    let button = UIButton(type: .custom)
    button.backgroundColor = NYPLConfiguration.primaryBackgroundColor
    
    if let fontName = fontName,
       let font = UIFont(name: fontName, size: fontSize) {
      button.titleLabel?.font = font
    } else {
      button.titleLabel?.font = UIFont.systemFont(ofSize: fontSize)
    }
    
    button.setTitle(title, for: .normal)
    button.titleLabel?.textAlignment = .justified
    
    if let color = titleColor {
      button.setTitleColor(color, for: .normal)
    }
    
    if let attributes = normalStateAttributes {
      let attributedString = NSAttributedString(string: title, attributes: attributes)
      button.setAttributedTitle(attributedString, for: .normal)
    }
    
    if let attributes = disabledStateAttributes {
      let attributedString = NSAttributedString(string: title, attributes: attributes)
      button.setAttributedTitle(attributedString, for: .disabled)
    }
    
    return button
  }
  
  private func newHorizontalLine() -> UIView {
    let view = UIView()
    view.backgroundColor = .lightGray
    view.autoSetDimension(.height, toSize: 0.5)
    return view
  }
  
  private func newVerticalLine() -> UIView {
    let view = UIView()
    view.backgroundColor = .lightGray
    view.autoSetDimension(.width, toSize: 0.5)
    return view
  }
}
