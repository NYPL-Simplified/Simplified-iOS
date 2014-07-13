#import "NYPLMyBooksState.h"

static NSString *const Downloading = @"downloading";
static NSString *const Unregistered = @"unregistered";

NYPLMyBooksState NYPLMyBooksStateFromString(NSString *const string)
{
  if([string isEqualToString:Downloading]) return NYPLMyBooksStateDownloading;
  if([string isEqualToString:Unregistered]) return NYPLMyBooksStateUnregistered;
  
  @throw NSInvalidArgumentException;
}

NSString *NYPLMyBooksStateToString(NYPLMyBooksState state)
{
  switch(state) {
    case NYPLMyBooksStateDownloading:
      return Downloading;
    case NYPLMyBooksStateUnregistered:
      return Unregistered;
  }
}