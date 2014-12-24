#import "NYPLReaderView.h"

@protocol NYPLReaderViewDelegate

- (void)readerView:(id<NYPLReaderView>)readerView didEncounterCorruptionForBook:(NYPLBook *)book;
- (void)readerView:(id<NYPLReaderView>)readerView didReceiveGesture:(NYPLReaderViewGesture)gesture;
- (void)readerViewDidFinishLoading:(id<NYPLReaderView>)readerView;

@end