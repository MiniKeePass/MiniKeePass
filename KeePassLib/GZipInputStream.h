//
//  GZipInputStream.h
//  MobileKeePass
//
//  Created by Jason Rush on 5/24/11.
//  Copyright 2011 Self. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <zlib.h>
#import "InputStream.h"

#define GZIP_INPUT_BUFFERSIZE 32768
#define GZIP_OUTPUT_BUFFERSIZE 16384

@interface GZipInputStream : InputStream {
    InputStream *inputStream;
    
    z_stream zstream;
    uint8_t inputBuffer[GZIP_INPUT_BUFFERSIZE];   
    uint8_t outputBuffer[GZIP_OUTPUT_BUFFERSIZE];
    uint32_t bufferOffset;
    uint32_t bufferSize;
    BOOL eof;
}

- (id)initWithInputStream:(InputStream*)stream;

@end
