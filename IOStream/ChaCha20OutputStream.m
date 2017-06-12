/*
 * Copyright 2017 Jason Rush and John Flanagan. All rights reserved.
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

#import "ChaCha20OutputStream.h"
#import "ChaCha20Cipher.h"

@interface ChaCha20OutputStream (PrivateMethods)
- (void)ensureBufferCapacity:(size_t)capacity;
@end

@implementation ChaCha20OutputStream

- (id)initWithOutputStream:(OutputStream *)stream key:(NSData *)key iv:(NSData *)iv {
    self = [super init];
    if (self) {
        outputStream = stream;
        
        cipher = [[ChaCha20Cipher alloc] init:key iv:iv];
        
        bufferCapacity = 1024*1024;
        buffer = malloc(bufferCapacity);
    }
    return self;
}

- (void)dealloc {
    free(buffer);
}

- (NSUInteger)write:(const void *)bytes length:(NSUInteger)bytesLength {
    // Ensure the buffer has enough space to store the encrypted data
    [self ensureBufferCapacity:bytesLength];
    if (buffer == nil) {
        @throw [NSException exceptionWithName:@"MallocException" reason:@"Failed allocate memory" userInfo:nil];
        
    }
    
    memcpy(buffer, bytes, bytesLength);
    
    // Encrypt the data
    [cipher Encrypt:buffer iOffset:0 count:bytesLength];
    
    // Write the encrypted data
    return [outputStream write:buffer length:bytesLength];
}

- (void)close {
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
