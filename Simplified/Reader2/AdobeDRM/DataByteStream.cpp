//
//  DataByteStream.cpp
//  SimplyE
//
//  Created by Vladimir Fedorov on 13.05.2020.
//  Copyright © 2020 NYPL Labs. All rights reserved.
//

#include <stdio.h>
#include "DataByteStream.h"

DataByteStream::DataByteStream(unsigned char *bytes, unsigned long len) {
  data = (unsigned char *)malloc(len);
  memcpy(data, bytes, len);
  length = len;
  position = 0;
}
DataByteStream::~DataByteStream() {
  free(data);
}

DataByteStream::size_type DataByteStream::BytesAvailable() _NOEXCEPT {
  return length - position;
}
DataByteStream::size_type DataByteStream::SpaceAvailable() const _NOEXCEPT {
  return 0;
}
bool DataByteStream::IsOpen() const _NOEXCEPT {
  return true;
}
void DataByteStream::Close() {
  
}
DataByteStream::size_type DataByteStream::ReadBytes(void *buf, DataByteStream::size_type len) {
  unsigned long copy_len = (length - position) < len ? (length - position) : len;
  if (copy_len <= 0) {
    return 0;
  }
  memcpy(buf, &data[position], copy_len);
  position += copy_len;
  return copy_len;
}
DataByteStream::size_type DataByteStream::ReadAllBytes(void** buf) {
  unsigned char* resbuf = nullptr;
  unsigned char* temp;
  size_t resbuflen = 0;
  
  unsigned char rdbuf [4096] = {0};
  size_t rdbuflen = 4096;
  std::size_t count = this->ReadBytes(rdbuf, rdbuflen);
  if(count) {
    resbuf = (unsigned char*)malloc(count);
    memcpy(resbuf, rdbuf, count);
    resbuflen = count;
  }
  while(count) {
    count = this->ReadBytes(rdbuf, rdbuflen);
    
    temp = (unsigned char*)malloc(count + resbuflen);
    memcpy(temp, resbuf, resbuflen);
    free(resbuf);
    resbuf = temp;
    memcpy(resbuf+resbuflen, rdbuf, count);
    resbuflen += count;
  }
  
  if (resbuflen > 0) {
    *buf = resbuf;
  }
  
  return resbuflen;
}
DataByteStream::size_type DataByteStream::WriteBytes(const void* buf, size_type len) {
  return 0;
}
bool DataByteStream::AtEnd() const _NOEXCEPT {
  return position == length;
}
int DataByteStream::Error() const _NOEXCEPT {
  return 0;
}

DataByteStream::size_type DataByteStream::Seek(DataByteStream::size_type by, std::ios::seekdir dir) {
  switch (dir) {
    case std::__1::ios_base::beg:
      // seeking starting from the beginning of the byte array, boundary check
      position = by >= length ? length : by;
      break;
    case std::__1::ios_base::cur:
      // seeking fom the current position, boundary check
      position = (position + by) >= length ? length : position + by;
      break;
    case std::__1::ios_base::end:
      // seeking from the end of the array, boundary check
      position = (length - by) <= 0 ? 0 : length - by;
      break;
  }
  return position;
}
DataByteStream::size_type DataByteStream::Position() const {
  return (DataByteStream::size_type)position;
}
void DataByteStream::Flush() {
  
}
std::shared_ptr<ePub3::SeekableByteStream> DataByteStream::Clone() const {
  return 0;
}
