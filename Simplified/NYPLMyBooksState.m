#import "NYPLMyBooksState.h"

static NSString *const Downloading = @"downloading";

NYPLMyBooksState NYPLMyBooksStateFromString(NSString *const string)
{
  if([string isEqualToString:Downloading]) return NYPLMyBooksStateDownloading;
  
  @throw NSInvalidArgumentException;
}

NSString *NYPLMyBooksStateToString(NYPLMyBooksState state)
{
  switch(state) {
    case NYPLMyBooksStateDownloading:
      return Downloading;
  }
}