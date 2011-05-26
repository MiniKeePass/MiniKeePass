//
//  AesInputStream.m
//  MobileKeePass
//
//  Created by Jason Rush on 5/22/11.
//  Copyright 2011 Self. All rights reserved.
//

#import "AesInputStream.h"

@interface AesInputStream (PrivateMethods)
- (BOOL)decrypt;
@end

@implementation AesInputStream

- (id)initWithInputStream:(InputStream*)stream key:(NSData*)key iv:(NSData*)iv {
    self = [super init];
    if (self) {
        inputStream = [stream retain];
        
        CCCryptorCreate(kCCDecrypt, kCCAlgorithmAES128, kCCOptionPKCS7Padding, key.bytes, kCCKeySizeAES256, iv.bytes, &cryptorRef);
        
        bufferOffset = 0;
        bufferSize = 0;
        eof = NO;
    }
    return self;
}

- (void)dealloc {
    [inputStream release];
    CCCryptorRelease(cryptorRef);
    [super dealloc];
}

- (NSUInteger)read:(void*)bytes length:(NSUInteger)bytesLength {
    NSUInteger remaining = bytesLength;
    NSUInteger offset = 0;
    NSUInteger n;
    
    while (remaining > 0) {
        if (bufferOffset >= bufferSize) {
            if (![self decrypt]) {
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

- (BOOL)decrypt {
    size_t decryptedBytes = 0;
    NSUInteger n;
    
    if (eof) {
        return NO;
    }
    
    bufferOffset = 0;
    bufferSize = 0;
    
    n = [inputStream read:inputBuffer length:AES_BUFFERSIZE];
    if (n > 0) {
        CCCryptorStatus cs = CCCryptorUpdate(cryptorRef, inputBuffer, n, outputBuffer, AES_BUFFERSIZE, &decryptedBytes);
        if (cs != kCCSuccess) {
            @throw [NSException exceptionWithName:@"IOException" reason:@"Error during decrypt" userInfo:nil];
        }
        
        bufferSize += decryptedBytes;
    }
    
    if (n < AES_BUFFERSIZE) {
        CCCryptorStatus cs = CCCryptorFinal(cryptorRef, outputBuffer + decryptedBytes, AES_BUFFERSIZE - decryptedBytes, &decryptedBytes);
        if (cs != kCCSuccess) {
            @throw [NSException exceptionWithName:@"DecryptError" reason:@"Error during decrypt" userInfo:nil];
        }
        
        eof = YES;
        bufferSize += decryptedBytes;
    }
    
    return YES;
}

@end
