//
//  marlin_sdk.hpp
//  MarlinSDK
//
//  Created on 2014/09/05.
//  Copyright (c) 2014 com.sonydadc All rights reserved.
//

#ifndef MARLIN_SDK_H_
#define MARLIN_SDK_H_

#include <memory>
#include <string>
#include <stdint.h>

namespace MarlinSDK
{
    class MarlinStream;
    class MarlinContext;
    
    typedef std::shared_ptr<MarlinStream>  MarlinStreamPtr;
    typedef std::shared_ptr<MarlinContext> MarlinContextPtr;
    
    class MarlinException : std::exception
    {
    };
    
    /* abstract */
    class MarlinError
    {
    public:
        virtual bool IsError() const = 0;
        virtual void TryThrow() const = 0;
        virtual uint32_t Code() const = 0;
        virtual const std::string CodeStr() const = 0;
    };

    /* abstract */
    class MarlinStream
    {
    protected:
        uint32_t           _length;
        uint32_t           _pos;
    public:
        MarlinStream()  {
            _length = 0;
            _pos = 0;
        }
        
        virtual ~MarlinStream() {}

        /**
         Get total length of the input stream
         @result Return length of whole stream data
         */
        virtual uint32_t GetLength()
        {
            return _length;
        }
        
        /**
         Seek to the position of the input stream
         @param position starting position
         @result Returns `true` if successful, `false` otherwise.
         */
        virtual bool Seek(uint32_t position) = 0;
        
        /**
         Tell position of the input stream
         @result position.
         */
        virtual uint32_t Tell()
        {
            return _pos;
        }
        
        /**
         Read data from actual position
         @param buffer allocated buffer prepared for the output
         @param length length of alocated buffer
         @result Return real length of the data written to the output stream
         */
        virtual uint32_t Read(void *buffer, uint32_t length) = 0;


        /**
         Similar to a normal io stream
         @result Returns `true` if the stream has reached the end of the file, `false` otherwise.
         */
        virtual bool eof()  { return _pos == _length; }

        /**
         Check if the stream can be used safely.
         @result Returns `true` if the stream is valid, `false` otherwise.
         */
        virtual bool IsValid() = 0;
    };
    
    /* abstract */
    class MarlinContext
    {
    public:
        static MarlinContextPtr CreateMarlinContext();
        
        virtual const MarlinError& GetLastError() = 0;

        /**
         create MarlinStream for decrypt
         @result created MarlinStream instance
         */
        virtual MarlinStreamPtr CreateDecryptor(MarlinStreamPtr source) = 0;
        
        /**
         create MarlinStream from file
         @result created MarlinStream instance
         */
        virtual MarlinStreamPtr CreateStreamFromFile(const std::string &path) = 0;

        /**
         create MarlinStream from buffer
         @result created MarlinStream instance
         */
        virtual MarlinStreamPtr CreateStreamFromBuffer(const void *buffer, uint32_t length) = 0;
    };
}

#endif /* MARLIN_SDK_H_ */
