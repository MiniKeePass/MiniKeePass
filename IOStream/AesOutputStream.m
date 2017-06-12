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
#import "AesOutputStream.h"

@interface AesOutputStream (PrivateMethods)
- (void)ensureBufferCapacity:(size_t)capacity;
@end

@implementation AesOutputStream

- (id)initWithOutputStream:(OutputStream *)stream key:(NSData *)key iv:(NSData *)iv {
    self = [super init];
    if (self) {
        outputStream = stream;
        
        CCCryptorCreate(kCCEncrypt, kCCAlgorithmAES128, kCCOptionPKCS7Padding, key.bytes, kCCKeySizeAES256, iv.bytes, &cryptorRef);
        
        bufferCapacity = 1024;
        buffer = malloc(bufferCapacity);
    }
    return self;
}

- (void)dealloc {
    CCCryptorRelease(cryptorRef);
    free(buffer);
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

    if (n > 0) {
        // Write the encrypted data
        if ([outputStream write:buffer length:n] != n) {
            @throw [NSException exceptionWithName:@"IOException" reason:@"Failed to write" userInfo:nil];
        }
    }
    
    return bytesLength;
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

- (void)ensureBufferCapacity:(size_t)capacity {
    // Check if we need to resize the internal buffer
    if (capacity > bufferCapacity) {
        free(buffer);
        
        bufferCapacity = capacity;
        buffer = malloc(bufferCapacity);
    }
}

@end
