/*
 * Copyright 2011-2012 Jason Rush and John Flanagan. All rights reserved.
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#import "GZipOutputStream.h"

@implementation GZipOutputStream

- (id)initWithOutputStream:(OutputStream *)stream {
    self = [super init];
    if (self) {
        outputStream = stream;
        
        zstream.zalloc = Z_NULL;
        zstream.zfree = Z_NULL;
        zstream.opaque = Z_NULL;
        zstream.avail_in = 0;
        zstream.avail_out = 0;
        zstream.next_in = Z_NULL;
        zstream.next_out = Z_NULL;
        if (deflateInit2(&zstream, Z_DEFAULT_COMPRESSION, Z_DEFLATED, 15 + 16, 8, Z_DEFAULT_STRATEGY) != Z_OK) {
            @throw [NSException exceptionWithName:@"IOException" reason:@"Failed to initialize zlib" userInfo:nil];
        }
    }
    return self;
}

- (NSUInteger)write:(const void *)bytes length:(NSUInteger)bytesLength {
    int n;
    
    zstream.avail_in = (unsigned int)bytesLength;
    zstream.next_in = (void *)bytes;
    
    while (zstream.avail_in > 0) {
        do {
            zstream.avail_out = GZIP_OUTPUT_BUFFERSIZE;
            zstream.next_out = buffer;
            
            if (deflate(&zstream, Z_NO_FLUSH) == Z_STREAM_ERROR) {
                deflateEnd(&zstream);
                @throw [NSException exceptionWithName:@"IOException" reason:@"Failed to deflate" userInfo:nil];
            }
            
            n = GZIP_OUTPUT_BUFFERSIZE - zstream.avail_out;
            if (n > 0) {
                if ([outputStream write:buffer length:n] != n) {
                    deflateEnd(&zstream);
                    @throw [NSException exceptionWithName:@"IOException" reason:@"Failed to write" userInfo:nil];
                }
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
