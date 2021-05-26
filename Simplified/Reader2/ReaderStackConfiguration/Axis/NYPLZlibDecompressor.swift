//
//  NYPLZlibDecompressor.swift
//  Open eBooks
//
//  Created by Raman Singh on 2021-05-18.
//  Copyright © 2021 NYPL Labs. All rights reserved.
//

import Foundation
import Compression

protocol NYPLZlibDecompressing {
  func decompress(sourceData: Data) -> Data?
}

struct NYPLZlibDecompressor: NYPLZlibDecompressing {
  
  /// Decompresses the given data using `ZLIB COMPRESSION` algorithm
  /// - Parameter sourceData: raw compressed data stream with no header
  /// - Returns: Decompressed data
  func decompress(sourceData: Data) -> Data? {
    var dataToReturn: Data?
    // Taken from https://www.hackingwithswift.com/example-code/system/how-to-compress-and-decompress-data
    if #available(iOS 13.0, *) {
      let result = try? (sourceData as NSData).decompressed(using: .zlib)
      if let result = result {
        dataToReturn = result as Data
      }
    }
    
    return dataToReturn ?? decompressInChunks(sourceData)
  }
  
  // Taken from https://developer.apple.com/documentation/compression/compression_zlib
  private func decompressInChunks(_ sourceData: Data) -> Data? {
    let bufferSize = 256
    let destinationBufferPointer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
    defer {
      destinationBufferPointer.deallocate()
    }
    
    // Create the compression_stream and throw an error if failed
    var stream = compression_stream()
    var status = compression_stream_init(
      &stream, COMPRESSION_STREAM_DECODE, COMPRESSION_ZLIB)
    
    guard status != COMPRESSION_STATUS_ERROR else {
      logError("Axis failed to initiate date decompression")
      return nil
    }
    defer {
      compression_stream_destroy(&stream)
    }
    
    // Stream setup after compression_stream_init
    // It is indeed important to do it after, since compression_stream_init
    // will zero all fields in stream
    stream.src_size = 0
    stream.dst_ptr = destinationBufferPointer
    stream.dst_size = bufferSize
    var start: Int = 0
    var end: Int = 0
    
    var dataChunkToDecompress: Data?
    var decompressedData = Data()
    repeat {
      var flags = Int32(0)
      
      // If this iteration has consumed all of the source data,
      // read a new tempData buffer from the input file.
      if stream.src_size == 0 {
        start = end
        end = min(bufferSize + start, sourceData.count)
        dataChunkToDecompress = sourceData.subdata(in: start..<end)
        
        stream.src_size = dataChunkToDecompress!.count
        if dataChunkToDecompress!.count < bufferSize {
          flags = Int32(COMPRESSION_STREAM_FINALIZE.rawValue)
        }
      }
      
      // Perform decompression.
      if let chunkToDecompress = dataChunkToDecompress {
        let count = chunkToDecompress.count
        
        chunkToDecompress.withUnsafeBytes {
          let baseAddress = $0.bindMemory(to: UInt8.self).baseAddress!
          
          stream.src_ptr = baseAddress.advanced(by: count - stream.src_size)
          status = compression_stream_process(&stream, flags)
        }
      }
      
      switch status {
      case COMPRESSION_STATUS_OK,
           COMPRESSION_STATUS_END:
        
        // Get the number of bytes put in the destination buffer. This is the
        // difference between stream.dst_size before the call (here bufferSize),
        // and stream.dst_size after the call.
        let count = bufferSize - stream.dst_size
        
        let outputData = Data(bytesNoCopy: destinationBufferPointer,
                              count: count,
                              deallocator: .none)
        
        // Append all produced bytes to decompressedData.
        decompressedData.append(outputData)
        
        // Reset the stream to receive the next batch of output.
        stream.dst_ptr = destinationBufferPointer
        stream.dst_size = bufferSize
      case COMPRESSION_STATUS_ERROR:
        logError("Axis failed mid decompression")
        return nil
        
      default:
        break
      }
    
    } while status == COMPRESSION_STATUS_OK
    
    return decompressedData
  }
  
  private func logError(_ summary: String) {
    NYPLErrorLogger.logError(
      withCode: .axisDRMFulfillmentFail,
      summary: summary)
  }
  
}

private extension compression_stream {
  init() {
      self = UnsafeMutablePointer<compression_stream>.allocate(capacity: 1).pointee
  }
}
