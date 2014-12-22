@protocol NYPLReaderView;

@protocol NYPLReaderViewDelegate

- (void)readerView:(id<NYPLReaderView>)readerView didEncounterCorruptionForBook:(NYPLBook *)book;

@end