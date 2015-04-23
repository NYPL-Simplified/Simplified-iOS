#import "NYPLXML.h"

@interface NYPLXML () <NSXMLParserDelegate>

@property (nonatomic) NSDictionary *attributes;
@property (nonatomic) NSMutableArray *mutableChildren;
@property (nonatomic) NSMutableString *mutableValue;
@property (nonatomic) NSString *name;
@property (nonatomic) NSString *namespaceURI;
@property (nonatomic, weak) NYPLXML *parent;
@property (nonatomic) NSString *qualifiedName;

@end

@implementation NYPLXML

+ (instancetype)XMLWithData:(NSData *const)data
{
  if(!data) return nil;

  NYPLXML *const document = [[self alloc] init];
  
  // TODO: This seemingly pointless copy appears to work around a bug with NSXMLParser that causes a
  // crash in 64-bit simulators. Calling |copy| does *not* solve the problem: It must be a mutable
  // copy for reasons completely unknown. Attempts to find a more pleasing workaround have been
  // unsuccessful thus far, but something should eventually be figured out.
  NSMutableData *const mutableData = [data mutableCopy];
  
  NSXMLParser *const parser = [[NSXMLParser alloc] initWithData:mutableData];
  parser.delegate = document;
  parser.shouldProcessNamespaces = YES;
  [parser parse];
  
  if(parser.parserError) {
    return nil;
  } else {
    NYPLXML *const root = document.children[0];
    root.parent = nil;
    return root;
  }
}

- (NSArray *)children
{
  return self.mutableChildren ? self.mutableChildren : @[];
}

- (NSString *)value
{
  return self.mutableValue ? self.mutableValue : @"";
}

- (NSArray *)childrenWithName:(NSString *const)name
{
  if(!name) return @[];
  
  NSMutableArray *const children = [NSMutableArray array];
  
  for(NYPLXML *const XML in self.children) {
    if([name isEqualToString:XML.name]) {
      [children addObject:XML];
    }
  }
  
  return children;
}

- (NYPLXML *)firstChildWithName:(NSString *const)name
{
  return [[self childrenWithName:name] firstObject];
}

#pragma mark NSXMLParserDelegate

- (void)parser:(NSXMLParser *const)parser
didStartElement:(NSString *const)name
  namespaceURI:(NSString *const)namespaceURI
 qualifiedName:(NSString *const)qualifiedName
    attributes:(NSDictionary *const)attributes
{
  NYPLXML *const child = [[[self class] alloc] init];
  child.attributes = attributes;
  child.name = name;
  child.namespaceURI = namespaceURI;
  child.parent = self;
  child.qualifiedName = qualifiedName;
  
  if(self.mutableChildren) {
    [self.mutableChildren addObject:child];
  } else {
    self.mutableChildren = [NSMutableArray arrayWithObject:child];
  }
  
  parser.delegate = child;
}

- (void)parser:(NSXMLParser *const)parser
 didEndElement:(__attribute__((unused)) NSString *)elementName
  namespaceURI:(__attribute__((unused)) NSString *)namespaceURI
 qualifiedName:(__attribute__((unused)) NSString *)qName
{
	parser.delegate = self.parent;
}

- (void)parser:(__attribute__((unused)) NSXMLParser *)parser
foundCharacters:(NSString *const)string
{
  if(self.mutableValue) {
    [self.mutableValue appendString:string];
  } else {
    self.mutableValue = [string mutableCopy];
  }
}

@end
