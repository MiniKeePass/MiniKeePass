//
//  GZipInputStream.m
//  MobileKeePass
//
//  Created by Jason Rush on 5/24/11.
//  Copyright 2011 Self. All rights reserved.
//

#import "GZipInputStream.h"

@interface GZipInputStream (PrivateMethods)
- (BOOL)decompress;
@end

@implementation GZipInputStream

- (id)initWithInputStream:(InputStream*)stream {
    self = [super init];
    if (self) {
        inputStream = [stream retain];
        
        zstream.zalloc = Z_NULL;
        zstream.zfree = Z_NULL;
        zstream.opaque = Z_NULL;
        zstream.avail_in = 0;
        zstream.avail_out = 0;
        zstream.next_in = Z_NULL;
        zstream.next_out = Z_NULL;
        if (inflateInit2(&zstream, 15 + 32) != Z_OK) {
            @throw [NSException exceptionWithName:@"IOException" reason:@"Failed to initialize zlib" userInfo:nil];
        }
    }
    return self;
}

- (void)dealloc {
    [inputStream release];
    [super dealloc];
}

- (NSUInteger)read:(void*)bytes length:(NSUInteger)bytesLength {
    NSUInteger remaining = bytesLength;
    NSUInteger offset = 0;
    NSUInteger n;
    
    while (remaining > 0) {
        if (bufferOffset >= bufferSize) {
            if (![self decompress]) {
                return bytesLength - remaining;
            }
        }
        
        n = MIN(remaining, bufferSize - bufferOffset);       
        memcpy(((uint8_t*)bytes) + offset, outputBuffer + bufferOffset, n);
        
        bufferOffset += n;
        
        offset += n;
        remaining -= n;
    }
    
    return bytesLength;
}

- (BOOL)decompress {
    int ret;
    int n;
    
    if (eof) {
        return NO;
    }
    
    zstream.avail_out = GZIP_OUTPUT_BUFFERSIZE;
    zstream.next_out = outputBuffer;
    
    do {
        // Check if we need more input data
        if (zstream.avail_in == 0) {
            n = [inputStream read:inputBuffer length:GZIP_INPUT_BUFFERSIZE];
            if (n <= 0) {
                inflateEnd(&zstream);
                @throw [NSException exceptionWithName:@"IOException" reason:@"Failed to read compressed data" userInfo:nil];
            }
            
            zstream.avail_in = n;
            zstream.next_in = inputBuffer;
        }
        
        // Inflate the input data
        ret = inflate(&zstream, Z_NO_FLUSH);
        if (ret != Z_OK) {
            inflateEnd(&zstream);
            
            if (ret != Z_STREAM_END) {
                @throw [NSException exceptionWithName:@"IOException" reason:@"Failed to inflate data" userInfo:nil];
            }
            
            eof = YES;
            break;
        }
    } while (zstream.avail_out > 0);
    
    if (eof) {
        bufferSize = GZIP_OUTPUT_BUFFERSIZE - zstream.avail_out;
    } else {
        bufferSize = GZIP_OUTPUT_BUFFERSIZE;
    }
    
    bufferOffset = 0;
    
    return YES;
}

@end
