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

class DataByteStream : public ePub3::SeekableByteStream {
private:
    unsigned char* data;
    unsigned long position;
    unsigned long length;
public:
    DataByteStream(unsigned char *bytes, unsigned long len);
    virtual ~DataByteStream();
    /*
     ByteStream (see byte_stream.h)
     */
    virtual size_type BytesAvailable() _NOEXCEPT;
    virtual size_type SpaceAvailable() const _NOEXCEPT;
    virtual bool IsOpen() const _NOEXCEPT;
    virtual void Close();
    virtual size_type ReadBytes(void* buf, size_type len);
    virtual size_type ReadAllBytes(void** buf);
    virtual size_type WriteBytes(const void* buf, size_type len);
    virtual bool AtEnd() const _NOEXCEPT;
    virtual int Error() const _NOEXCEPT;
    /*
     SeekableByteStream (see byte_stream.h)
     */
    virtual size_type Seek(size_type by, std::ios::seekdir dir);
    virtual size_type Position() const;
    virtual void Flush();
    virtual std::shared_ptr<SeekableByteStream> Clone() const;
};


#endif /* DataByteStream_h */
