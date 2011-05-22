//
//  HashedInputStream.h
//  MobileKeePass
//
//  Created by Jason Rush on 5/22/11.
//  Copyright 2011 Self. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "InputStream.h"

@interface HashedInputStream : InputStream {
    InputStream *inputStream;
    
    uint32_t blockIndex;
    
    uint8_t *buffer;
    uint32_t bufferOffset;
    uint32_t bufferLength;
    
    BOOL eof;
}

- (id)initWithInputStream:(InputStream*)stream;

@end
