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
#import "AesInputStream.h"

@interface AesInputStream (PrivateMethods)
- (BOOL)decrypt;
@end

@implementation AesInputStream

- (id)initWithInputStream:(InputStream *)stream key:(NSData *)key iv:(NSData *)iv {
    self = [super init];
    if (self) {
        inputStream = stream;
        
        CCCryptorCreate(kCCDecrypt, kCCAlgorithmAES128, kCCOptionPKCS7Padding, key.bytes, kCCKeySizeAES256, iv.bytes, &cryptorRef);
        
        bufferOffset = 0;
        bufferSize = 0;
        eof = NO;
    }
    return self;
}

- (void)dealloc {
    CCCryptorRelease(cryptorRef);
}

- (NSUInteger)read:(void *)bytes length:(NSUInteger)bytesLength {
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
        memcpy(((uint8_t *)bytes) + offset, outputBuffer + bufferOffset, n);
        
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
