import UIKit

/// This class is similar to `UITableViewController` except it is not broken on iOS 8,
/// does not implement a refresh control, and may be missing a couple other nicities.
///
/// On iOS 8, `UITableViewController` has a bug where `init(style:)` will inappropriately
/// call `init(nibName:bundle:)` on `self`. This makes subclassing `UITableViewController`
/// impossible if you wish to provide a new non-zero-argument initializer that sets instance
/// variables because you *must* implement `init(nibName:bundle:)` or you'll get a crash at
/// runtime and there's no way to pass `init(nibName:bundle:)` the arguments you need.
///
/// See http://stackoverflow.com/a/30719434 for more information.
class TableViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
  let tableView: UITableView
  var clearsSelectedOnViewWillAppear = true
  
  init(style: UITableViewStyle) {
    self.tableView = UITableView(frame: CGRect.zero, style: style)
    super.init(nibName: nil, bundle: nil)
    self.tableView.dataSource = self
    self.tableView.delegate = self
  }
  
  @available(*, unavailable)
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  // MARK: UIView
  
  override func viewWillAppear(_ animated: Bool) {
    if self.clearsSelectedOnViewWillAppear {
      if let indexPathForSelectedRow = self.tableView.indexPathForSelectedRow {
        self.tableView.deselectRow(at: indexPathForSelectedRow, animated: true)
      }
    }
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    self.view.addSubview(self.tableView)
    self.tableView.autoPinEdgesToSuperviewEdges()
  }
  
  // MARK: UITableViewDataSource
  
  /// This should be overridden in all subclasses.
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return 0
  }
  
  /// This should be overridden in all subclasses.
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    return UITableViewCell()
  }
}
