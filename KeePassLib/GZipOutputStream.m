//
//  GZipOutputStream.m
//  MobileKeePass
//
//  Created by Jason Rush on 5/25/11.
//  Copyright 2011 Self. All rights reserved.
//

#import "GZipOutputStream.h"

@implementation GZipOutputStream

- (id)initWithOutputStream:(OutputStream*)stream {
    self = [super init];
    if (self) {
        outputStream = [stream retain];
        
        zstream.zalloc = Z_NULL;
        zstream.zfree = Z_NULL;
        zstream.opaque = Z_NULL;
        zstream.avail_in = 0;
        zstream.avail_out = 0;
        zstream.next_in = Z_NULL;
        zstream.next_out = Z_NULL;
        if (deflateInit(&zstream, Z_DEFAULT_COMPRESSION) != Z_OK) {
            @throw [NSException exceptionWithName:@"IOException" reason:@"Failed to initialize zlib" userInfo:nil];
        }
    }
    return self;
}

- (void)dealloc {
    [outputStream release];
    [super dealloc];
}

- (NSUInteger)write:(const void *)bytes length:(NSUInteger)bytesLength {
    int n;
    
    zstream.avail_in = bytesLength;
    zstream.next_in = (void*)bytes;
    
    while (zstream.avail_in > 0) {
        do {
            zstream.avail_out = GZIP_OUTPUT_BUFFERSIZE;
            zstream.next_out = buffer;
            
            if (deflate(&zstream, Z_NO_FLUSH) == Z_STREAM_ERROR) {
                deflateEnd(&zstream);
                @throw [NSException exceptionWithName:@"IOException" reason:@"Failed to deflate" userInfo:nil];
            }
            
            n = GZIP_OUTPUT_BUFFERSIZE - zstream.avail_out;
            if ([outputStream write:buffer length:n] != n) {
                deflateEnd(&zstream);
                @throw [NSException exceptionWithName:@"IOException" reason:@"Failed to write" userInfo:nil];
            }
        } while (zstream.avail_out == 0);
    }
    
    return bytesLength;
}

- (void)close {
    int ret;
    int n;
    
    zstream.avail_in = 0;
    zstream.next_in = Z_NULL;
    
    do {
        zstream.avail_out = GZIP_OUTPUT_BUFFERSIZE;
        zstream.next_out = buffer;
        
        if ((ret = deflate(&zstream, Z_FINISH)) == Z_STREAM_ERROR) {
            deflateEnd(&zstream);
            @throw [NSException exceptionWithName:@"IOException" reason:@"Failed to flush stream" userInfo:nil];
        }
        
        n = GZIP_OUTPUT_BUFFERSIZE - zstream.avail_out;
        if ([outputStream write:buffer length:n] != n) {
            deflateEnd(&zstream);
            @throw [NSException exceptionWithName:@"IOException" reason:@"Failed to write" userInfo:nil];
        }
    } while (ret != Z_STREAM_END);
    
    deflateEnd(&zstream);
    
    [outputStream close];
}

@end
