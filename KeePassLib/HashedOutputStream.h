//
//  HashedOutputData.h
//  MobileKeePass
//
//  Created by Jason Rush on 5/22/11.
//  Copyright 2011 Self. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OutputStream.h"

@interface HashedOutputStream : OutputStream {
    OutputStream *outputStream;
    
    uint32_t blockSize;
    uint32_t blockIndex;
    
    uint8_t *buffer;
    uint32_t bufferOffset;
}

- (id)initWithOutputStream:(OutputStream*)stream blockSize:(uint32_t)size;

@end
