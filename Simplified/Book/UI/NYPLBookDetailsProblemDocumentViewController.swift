@objcMembers class NYPLBookDetailsProblemDocumentViewController : UIViewController {
  let doc: NYPLProblemDocument
  let book: NYPLBook?
  
  let elementSpacing = CGFloat(12)
  weak var scrollView: UIScrollView?
  weak var backButton: UIButton?
  weak var closeButton: UIButton?
  weak var label: UILabel?
  weak var submitButton: UIButton?
  
  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  init(problemDocument: NYPLProblemDocument, book: NYPLBook?) {
    self.doc = problemDocument
    self.book = book
    super.init(nibName: nil, bundle: nil)
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    let margins = self.view.layoutMarginsGuide
    
    self.view.backgroundColor = NYPLConfiguration.primaryBackgroundColor
    
    // ScrollView Setup
    let scrollView = UIScrollView()
    scrollView.translatesAutoresizingMaskIntoConstraints = false
    self.scrollView = scrollView
    scrollView.alwaysBounceHorizontal = false
    scrollView.alwaysBounceVertical = true
    self.view.addSubview(scrollView)
    
    // NavBar
    var navBar: UIView?
    if UIDevice.current.userInterfaceIdiom == .pad && NYPLRootTabBarController.shared()!.traitCollection.horizontalSizeClass != .compact {
      navBar = UIView.init()
      navBar!.translatesAutoresizingMaskIntoConstraints = false
      
      // Back Button
      let backButton = UIButton.init(type: .system)
      self.backButton = backButton
      backButton.translatesAutoresizingMaskIntoConstraints = false
      backButton.setTitle("Back", for: .normal)
      backButton.setTitleColor(NYPLConfiguration.mainColor(), for: .normal)
      backButton.contentHorizontalAlignment = .left
      backButton.contentEdgeInsets = UIEdgeInsets.init(top: 0, left: 0, bottom: 0, right: 2)
      backButton.addTarget(self, action: #selector(backButtonWasPressed), for: .touchDown)
      navBar!.addSubview(backButton)
      
      // Close Button
      let closeButton = UIButton.init(type: .system)
      self.closeButton = closeButton
      closeButton.translatesAutoresizingMaskIntoConstraints = false
      closeButton.setTitle("Close", for: .normal)
      closeButton.setTitleColor(NYPLConfiguration.mainColor(), for: .normal)
      closeButton.contentHorizontalAlignment = .right
      closeButton.contentEdgeInsets = UIEdgeInsets.init(top: 0, left: 2, bottom: 0, right: 0)
      closeButton.addTarget(self, action: #selector(closeButtonWasPressed), for: .touchDown)
      navBar!.addSubview(closeButton)
      
      scrollView.addSubview(navBar!)
      
      // Layout navbar
      let buttonHeight = max(backButton.intrinsicContentSize.height, closeButton.intrinsicContentSize.height)
      navBar!.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: elementSpacing).isActive = true
      navBar!.leadingAnchor.constraint(equalTo: margins.leadingAnchor).isActive = true
      navBar!.trailingAnchor.constraint(equalTo: margins.trailingAnchor).isActive = true
      navBar!.widthAnchor.constraint(greaterThanOrEqualToConstant: backButton.intrinsicContentSize.width + closeButton.intrinsicContentSize.width).isActive = true
      navBar!.heightAnchor.constraint(equalToConstant: buttonHeight).isActive = true
      
      backButton.leadingAnchor.constraint(equalTo: navBar!.leadingAnchor).isActive = true
      backButton.topAnchor.constraint(equalTo: navBar!.topAnchor).isActive = true
      
      closeButton.trailingAnchor.constraint(equalTo: navBar!.trailingAnchor).isActive = true
      closeButton.topAnchor.constraint(equalTo: navBar!.topAnchor).isActive = true
    }

    // Info Label
    let label = UILabel.init()
    self.label = label
    label.translatesAutoresizingMaskIntoConstraints = false
    label.numberOfLines = 0
    label.attributedText = generateAttributedText(problemDocument: self.doc)
    
    // Submit button
    let submitButton = UIButton.init(type: .roundedRect)
    self.submitButton = submitButton
    submitButton.translatesAutoresizingMaskIntoConstraints = false
    submitButton.setTitle("Send to Support", for: .normal)
    submitButton.isEnabled = AccountsManager.shared.currentAccount?.supportEmail != nil
    submitButton.addTarget(self, action: #selector(submitButtonWasPressed), for: .touchDown)
    
    scrollView.addSubview(label)
    scrollView.addSubview(submitButton)
    
    // Layout
    if navBar != nil {
      label.topAnchor.constraint(equalTo: navBar!.bottomAnchor, constant: elementSpacing).isActive = true
    } else {
      label.topAnchor.constraint(equalTo: scrollView.topAnchor).isActive = true
    }
    label.leadingAnchor.constraint(equalTo: margins.leadingAnchor).isActive = true
    label.trailingAnchor.constraint(equalTo: margins.trailingAnchor).isActive = true
    
    submitButton.topAnchor.constraint(equalTo: label.bottomAnchor, constant: elementSpacing).isActive = true
    submitButton.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
    
    scrollView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
    scrollView.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
    scrollView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
    scrollView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
    
    // ScrollContentSize
    scrollView.contentSize = calculateContentSize()
  }
  
  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    
    self.scrollView?.contentSize = calculateContentSize()
  }
  
  override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)
    if #available(iOS 12.0, *),
       let previousTraitCollection = previousTraitCollection,
       UIScreen.main.traitCollection.userInterfaceStyle != previousTraitCollection.userInterfaceStyle
    {
      updateColors()
    }
  }
  
  private func updateColors() {
    backButton?.setTitleColor(NYPLConfiguration.mainColor(), for: .normal)
    closeButton?.setTitleColor(NYPLConfiguration.mainColor(), for: .normal)
  }
  
  func calculateContentSize() -> CGSize {
    var height = CGFloat.zero
    height += max(self.backButton?.bounds.height ?? 0, self.closeButton?.bounds.height ?? 0)
    height += self.label?.bounds.height ?? 0
    height += self.submitButton?.bounds.height ?? 0
    height += self.elementSpacing * (self.backButton == nil ? 3 : 4)
    let width = max(self.submitButton?.bounds.width ?? 0, (self.backButton?.bounds.width ?? 0) + (self.closeButton?.bounds.width ?? 0))
    return CGSize(width: width, height: height)
  }
  
  func generateAttributedText(problemDocument: NYPLProblemDocument) -> NSAttributedString {
    let normalFont = UIFont.systemFont(ofSize: 12)
    let boldFont = UIFont.boldSystemFont(ofSize: 12)
    let type = problemDocument.type ?? "n/a"
    let title = problemDocument.title ?? "n/a"
    let status = problemDocument.status == nil ? "n/a" : "\(problemDocument.status!)"
    let detail = problemDocument.detail ?? "n/a"
    let instance = problemDocument.instance ?? "n/a"
    let result = NSMutableAttributedString.init()
    result.append(NSAttributedString(string: "Type:\n", attributes: [.font : boldFont]))
    result.append(NSAttributedString(string: "\(type)\n\n", attributes: [.font : normalFont]))
    result.append(NSAttributedString(string: "Title:\n", attributes: [.font : boldFont]))
    result.append(NSAttributedString(string: "\(title)\n\n", attributes: [.font : normalFont]))
    result.append(NSAttributedString(string: "Status:\n", attributes: [.font : boldFont]))
    result.append(NSAttributedString(string: "\(status)\n\n", attributes: [.font : normalFont]))
    result.append(NSAttributedString(string: "Detail:\n", attributes: [.font : boldFont]))
    result.append(NSAttributedString(string: "\(detail)\n\n", attributes: [.font : normalFont]))
    result.append(NSAttributedString(string: "Instance:\n", attributes: [.font : boldFont]))
    result.append(NSAttributedString(string: "\(instance)\n", attributes: [.font : normalFont]))
    return result
  }
  
  // Selectors
  
  func backButtonWasPressed() {
    self.navigationController?.popViewController(animated: true)
  }
  
  func closeButtonWasPressed() {
    self.dismiss(animated: true, completion: nil)
  }
  
  func submitButtonWasPressed() {
    guard let supportEmail = AccountsManager.shared.currentAccount?.supportEmail else {
      Log.error(#file, "Missing support email for library \(AccountsManager.shared.currentAccountId ?? "")")
      return
    }
    
    let alert = UIAlertController.init(title: "Report a Problem", message: "Are you sure you want to email this error log to \(AccountsManager.shared.currentAccount?.name ?? "library") support?", preferredStyle: .alert)
    alert.addAction(UIAlertAction.init(title: "Cancel", style: .cancel, handler: nil))
    alert.addAction(UIAlertAction.init(title: "Send email", style: .default, handler: { (action) in
      let labelText = self.label?.attributedText?.string ?? ""
      let body = """
        \(labelText)\n\
        DeviceModel:\n\(UIDevice.current.model)\n\n
        DeviceSystemName:\n\(UIDevice.current.systemName)\n\n
        DeviceSystemVersion:\n\(UIDevice.current.systemVersion)\n\n
        DeviceIdiom:\n\(UIDevice.current.userInterfaceIdiom)\n\n
        BookTitle:\n\(self.book?.title ?? "n/a")\n\n
        BookIdentifier:\n\(self.book?.identifier ?? "n/a")\n\n
      """
      ProblemReportEmail.sharedInstance.beginComposing(
        to: supportEmail,
        presentingViewController: self,
        body: body
      )
    }))
    self.present(alert, animated: true, completion: nil)
  }
}
