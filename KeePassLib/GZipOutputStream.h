//
//  GZipOutputStream.h
//  MobileKeePass
//
//  Created by Jason Rush on 5/25/11.
//  Copyright 2011 Self. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <zlib.h>
#import "OutputStream.h"

#define GZIP_OUTPUT_BUFFERSIZE 16384

@interface GZipOutputStream : OutputStream {
    OutputStream *outputStream;
    
    z_stream zstream;
    uint8_t buffer[GZIP_OUTPUT_BUFFERSIZE];
}

- (id)initWithOutputStream:(OutputStream*)stream;

@end
