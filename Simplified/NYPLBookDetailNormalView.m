#import "NYPLConfiguration.h"

#import "NYPLBookDetailNormalView.h"

@interface NYPLBookDetailNormalView ()

@property (nonatomic) UIView *backgroundView;
@property (nonatomic) UIButton *deleteButton;
@property (nonatomic) UIButton *downloadButton;
@property (nonatomic) UIButton *readButton;

@end

@implementation NYPLBookDetailNormalView

#pragma mark UIView

- (instancetype)initWithWidth:(CGFloat)width
{
  self = [super initWithFrame:CGRectMake(0, 0, width, 70)];
  if(!self) return nil;
  
  self.backgroundView = [[UIView alloc] init];
  self.backgroundView.backgroundColor = [NYPLConfiguration mainColor];
  [self addSubview:self.backgroundView];
  
  self.deleteButton = [UIButton buttonWithType:UIButtonTypeSystem];
  [self.deleteButton addTarget:self
                        action:@selector(didSelectDelete)
              forControlEvents:UIControlEventTouchUpInside];
  [self addSubview:self.deleteButton];
  
  self.downloadButton = [UIButton buttonWithType:UIButtonTypeSystem];
  [self.downloadButton addTarget:self
                          action:@selector(didSelectDownload)
                forControlEvents:UIControlEventTouchUpInside];
  [self addSubview:self.downloadButton];
  
  self.readButton = [UIButton buttonWithType:UIButtonTypeSystem];
  [self.readButton addTarget:self
                      action:@selector(didSelectRead)
            forControlEvents:UIControlEventTouchUpInside];
  [self addSubview:self.readButton];
  
  return self;
}

- (void)layoutSubviews
{
  self.backgroundView.frame = CGRectMake(0, 0, CGRectGetWidth(self.frame), 30);
}

#pragma mark -

- (void)setState:(NYPLBookDetailNormalViewState const)state
{
  _state = state;
  
  switch(state) {
    case NYPLBookDetailNormalViewStateUnregistered:
      // fallthrough
    case NYPLBookDetailNormalViewStateDownloadNeeded:
      self.deleteButton.hidden = YES;
      self.downloadButton.hidden = NO;
      self.readButton.hidden = YES;
      break;
    case NYPLBookDetailNormalViewStateDownloadSuccessful:
      self.deleteButton.hidden = NO;
      self.downloadButton.hidden = YES;
      self.readButton.hidden = NO;
      break;
  }
}

- (void)didSelectDelete
{
  [self.delegate didSelectDeleteForBookDetailNormalView:self];
}

- (void)didSelectDownload
{
  [self.delegate didSelectDownloadForBookDetailNormalView:self];
}

- (void)didSelectRead
{
  [self.delegate didSelectReadForBookDetailNormalView:self];
}

@end
