//
//  DataByteStream.h
//  SimplyE
//
//  Created by Vladimir Fedorov on 13.05.2020.
//  Copyright © 2020 NYPL Labs. All rights reserved.
//

#ifndef DataByteStream_h
#define DataByteStream_h

#import <ePub3/utilities/byte_stream.h>

/**
 DataByteStream provides a way to convert array of bytes to a ePub3::SeekableByteStream object
 */
class DataByteStream : public ePub3::SeekableByteStream {
private:
  /// Internal data array
  unsigned char* data;
  
  /// Stream position
  unsigned long position;
  
  /// Length of the array
  unsigned long length;
  
public:
  DataByteStream(unsigned char *bytes, unsigned long len);
  virtual ~DataByteStream();
  
  /*
   ByteStream (see byte_stream.h)
   */
  
  /// Returns the number of bytes that can be read at this time.
  virtual size_type BytesAvailable() _NOEXCEPT;
  
  /// Returns the amount of space available for writing at this time.
  virtual size_type SpaceAvailable() const _NOEXCEPT;
  
  /// Determine whether the stream is currently open (i.e. usable).
  /// Always returns true
  virtual bool IsOpen() const _NOEXCEPT;
  
  /// Close the stream.
  /// Has no effect on DataByteStream
  virtual void Close();
  
  /**
   Read some data from the stream.
   @param buf A buffer into which to place any retrieved data.
   @param len The number of bytes that can be stored in `buf`.
   @result Returns the number of bytes actually copied into `buf`.
   */
  virtual size_type ReadBytes(void* buf, size_type len);
  
  /**
   Read all data from the stream.
   @param buf A pointer to a buffer which will be allocated
   @result Returns the number of bytes copied into `buf`.
   */
  virtual size_type ReadAllBytes(void** buf);
  
  /// Write data to the stream
  /// Has no effect on DataByteStream
  virtual size_type WriteBytes(const void* buf, size_type len);
  
  
  /// Returns `true` if an EOF status has occurred.
  virtual bool AtEnd() const _NOEXCEPT;
  
  /// Returns any error code reported by the underlying system.
  /// Always returns no error for DataByteStream
  virtual int Error() const _NOEXCEPT;
  
  /*
   SeekableByteStream (see byte_stream.h)
   */
  
  /**
   Seek to a position within the array of bytes.
   @param by The amount to move the file position.
   @param dir The starting point for the position calculation: current position,
   start of file, or end of file.
   @result The new file position. This may be different from the requested position,
   if for instance the file was not large enough to accomodate the request.
   */
  virtual size_type Seek(size_type by, std::ios::seekdir dir);
  
  /**
   Returns the current position within the target file.
   @result The current file position.
   */
  virtual size_type Position() const;
  
  /**
   Ensures that all written data is pushed to permanent storage.
   Has no effect on DataByteStream
   */
  virtual void Flush();
  
  /**
   Creates a new independent stream object referring to the same data array.
   @result A new DataByteStream instance.
   */
  virtual std::shared_ptr<SeekableByteStream> Clone() const;
};


#endif /* DataByteStream_h */
