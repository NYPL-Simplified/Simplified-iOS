import UIKit

@objc class NYPLReaderBookmarkCell: UITableViewCell {
  @IBOutlet weak var chapterLabel: UILabel!
  @IBOutlet weak var pageNumberLabel: UILabel!

  private static var dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.timeStyle = .short
    formatter.dateStyle = .short
    return formatter
  }()

  @objc
  func config(withChapterName chapterName: String,
              percentInChapter: String,
              rfc3339DateString: String) {
    backgroundColor = .clear
    chapterLabel.text = chapterName

    let formattedBookmarkDate = prettyDate(forRFC3339String: rfc3339DateString)
    let progress = String.localizedStringWithFormat(NSLocalizedString("%@ through chapter", comment: "A concise string that expreses the percent progress, where %@ is the percentage"), percentInChapter)
    pageNumberLabel.text = "\(formattedBookmarkDate) - \(progress)"

    let textColor = NYPLReaderSettings.shared().foregroundColor
    chapterLabel.textColor = textColor;
    pageNumberLabel.textColor = textColor;
  }

  private func prettyDate(forRFC3339String dateStr: String) -> String {
    guard let date = (NSDate(rfc3339String: dateStr) as Date?) else {
      return ""
    }

    return NYPLReaderBookmarkCell.dateFormatter.string(from: date)
  }
}
