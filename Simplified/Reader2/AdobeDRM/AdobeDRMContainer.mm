//
//  AdobeDRMContainer.mm
//  SimplyE
//
//  Created by Vladimir Fedorov on 13.05.2020.
//  Copyright © 2020 NYPL Labs. All rights reserved.
//

#import "AdobeDRMContainer.h"

#include <memory>
#import <ePub3/nav_table.h>
#import <ePub3/container.h>
#import <ePub3/initialization.h>
#import <ePub3/utilities/byte_stream.h>
#import <ePub3/utilities/error_handler.h>
#import "adept_filter.h"
#import "ADEPT/ADEPT.h"
#import "ePub3/utilities/make_unique.h"
#import "DataByteStream.h"

static id acsdrm_lock = nil;

@interface AdobeDRMContainer () {
  @private std::shared_ptr<ePub3::Container> container;
  @private ePub3::Package *package;
  @private ePub3::ConstManifestItemPtr manifestItem;
}
@end


@implementation AdobeDRMContainer: NSObject

- (instancetype)initWithURL:(NSURL *)fileURL {
  
  if (self = [super init]) {
    
    acsdrm_lock = [[NSObject alloc] init];
    
    NSString *path = fileURL.path;
    
    ePub3::ErrorHandlerFn sdkErrorHandler = ^(const ePub3::error_details& err) {
      BOOL isSevereEpubError = NO;
      if (err.is_spec_error()
          && (err.severity() == ePub3::ViolationSeverity::Critical
              || err.severity() == ePub3::ViolationSeverity::Major))
        isSevereEpubError = YES;
      
      return ePub3::DefaultErrorHandler(err);
    };
    ePub3::SetErrorHandler(sdkErrorHandler);
    
    ePub3::InitializeSdk();
    ePub3::PopulateFilterManager();
    ePub3::AdeptFilter::Register();
    
    try {
      container = ePub3::Container::OpenContainer(path.UTF8String);
      
    }
    catch (std::exception& e) { // includes ePub3::ContentModuleException
      auto msg = e.what();
      std::cout << msg << std::endl;
    }
    catch (...) {
    }
    
    if (container == nullptr) {
      return nil;
    }
    
    package = container->DefaultPackage().get();
    ePub3::string s = package->TableOfContents()->SourceHref();
    manifestItem = package->ManifestItemAtRelativePath(s);
  }
  return self;
}

- (void *)getDecodedByteStream:(void *)currentByteStream isRangeRequest:(BOOL)isRangeRequest {
  // Get the manifest item initWithURL: saves for further use
  ePub3::ManifestItemPtr m = std::const_pointer_cast<ePub3::ManifestItem>(manifestItem);
  size_t numFilters = package->GetFilterChainSize(m);
  ePub3::ByteStream *byteStream = nullptr;
  ePub3::SeekableByteStream *rawInput = (ePub3::SeekableByteStream *)currentByteStream;
  
  if (numFilters == 0)
  {
    byteStream = (ePub3::ByteStream *) currentByteStream; // is actually a SeekableByteStream
  }
  else if (numFilters == 1 && isRangeRequest)
  {
    byteStream = package->GetFilterChainByteStreamRange(m, rawInput).release(); // is *not* a SeekableByteStream, but wraps one
    if (byteStream == nullptr)
    {
      byteStream = package->GetFilterChainByteStream(m, rawInput).release(); // is *not* a SeekableByteStream, but wraps one
    }
  }
  else
  {
    byteStream = package->GetFilterChainByteStream(m, rawInput).release(); // is *not* a SeekableByteStream, but wraps one
  }
  
  return byteStream;
  
}


- (NSData *)decodeData:(NSData *)data {
  
  @synchronized (acsdrm_lock) {
    NSUInteger contentLength;
    NSUInteger contentLengthCheck;
    UInt8 buffer[1024 * 256];
    std::unique_ptr<ePub3::ByteStream> byteStream;
    // DataByteStream converts NSData to SeekableByteStream for content filters
    DataByteStream *dataByteStream = new DataByteStream((unsigned char *)[data bytes], (unsigned long)data.length);
    byteStream.reset((ePub3::ByteStream *)[self getDecodedByteStream:dataByteStream isRangeRequest:NO]);
    contentLength = byteStream->BytesAvailable();
    contentLengthCheck = 0;
    // Create NSData from decrypted byte stream
    NSMutableData *md = [[NSMutableData alloc] initWithCapacity:contentLength == 0 ? 1 : contentLength];
    while (YES)
    {
      std::size_t count = byteStream->ReadBytes(buffer, sizeof(buffer));
      if (count == 0) {
        break;
      }
      [md appendBytes:buffer length:count];
    }
    // The last byte defines the amount of bytes to cut from data
    // in R2Streamer FullDRMInputStream.swift
    const char padding[] = {1};
    [md appendBytes:padding length:1];
    return [md copy];
  }
}

@end
