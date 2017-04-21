// TODO: This class pulls the current color scheme from NYPLReaderSettings. This may or may not be
// an appropriate way of handling color schemes. If the color scheme changes, all tables containing
// a NYPLReaderTOCCell must be reloaded.

@interface NYPLReaderTOCCell : UITableViewCell

@property (nonatomic) NSUInteger nestingLevel;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;

@end
