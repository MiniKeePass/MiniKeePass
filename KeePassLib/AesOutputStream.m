//
//  AesOutputStream.m
//  MobileKeePass
//
//  Created by Jason Rush on 5/22/11.
//  Copyright 2011 Self. All rights reserved.
//

#import "AesOutputStream.h"

@interface AesOutputStream (PrivateMethods)
- (void)ensureBufferCapacity:(uint32_t)capacity;
@end

@implementation AesOutputStream

- (id)initWithOutputStream:(OutputStream*)stream key:(NSData*)key iv:(NSData*)iv {
    self = [super init];
    if (self) {
        outputStream = [stream retain];
        
        CCCryptorCreate(kCCEncrypt, kCCAlgorithmAES128, kCCOptionPKCS7Padding, key.bytes, kCCKeySizeAES256, iv.bytes, &cryptorRef);
        
        bufferCapacity = 1024;
        buffer = malloc(bufferCapacity);
    }
    return self;
}

- (void)dealloc {
    [outputStream release];
    CCCryptorRelease(cryptorRef);
    free(buffer);
    [super dealloc];
}

- (NSUInteger)write:(const void *)bytes length:(NSUInteger)bytesLength {
    // Ensure the buffer has enough space to store the encrypted data
    [self ensureBufferCapacity:CCCryptorGetOutputLength(cryptorRef, bytesLength, NO)];
    
    // Encrypt the data
    size_t n = 0;
    CCCryptorStatus cs = CCCryptorUpdate(cryptorRef, bytes, bytesLength, buffer, bufferCapacity, &n);
    if (cs != kCCSuccess) {
        @throw [NSException exceptionWithName:@"EncryptError" reason:@"Failed to encrypt" userInfo:nil];
    }
    
    // Write the encrypted data
    return [outputStream write:buffer length:n];
}

- (void)close {
    // Encrypt the last block
    size_t n = 0;
    CCCryptorStatus cs = CCCryptorFinal(cryptorRef, buffer, bufferCapacity, &n);
    if (cs != kCCSuccess) {
        @throw [NSException exceptionWithName:@"EncryptError" reason:@"Failed to encrypt" userInfo:nil];
    }
    
    // Write the encrypted data
    [outputStream write:buffer length:n];
    
    [outputStream close];
}

- (void)ensureBufferCapacity:(uint32_t)capacity {
    // Check if we need to resize the internal buffer
    if (capacity > bufferCapacity) {
        free(buffer);
        
        bufferCapacity = capacity;
        buffer = malloc(bufferCapacity);
    }
}

@end
