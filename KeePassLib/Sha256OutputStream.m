//
//  Sha256OutputStream.m
//  MobileKeePass
//
//  Created by Jason Rush on 5/22/11.
//  Copyright 2011 Self. All rights reserved.
//

#import "Sha256OutputStream.h"

@implementation Sha256OutputStream

- (id)initWithOutputStream:(OutputStream*)stream {
    self = [super init];
    if (self) {
        outputStream = [stream retain];
        
        CC_SHA256_Init(&shaCtx);
    }
    return self;
}

- (void)dealloc {
    [outputStream release];
    [super dealloc];
}

- (NSUInteger)write:(const void *)bytes length:(NSUInteger)bytesLength {
    CC_SHA256_Update(&shaCtx, bytes, bytesLength);
    
    return [outputStream write:bytes length:bytesLength];
}

- (void)close {
    [outputStream close];
    
    CC_SHA256_Final(hash, &shaCtx);
}

- (uint8_t*)getHash {
    return hash;
}

@end
