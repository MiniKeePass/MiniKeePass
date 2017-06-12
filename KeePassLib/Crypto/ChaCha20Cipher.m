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

#import "ChaCha20Cipher.h"
#import <CommonCrypto/CommonDigest.h>
#import <Security/Security.h>

static uint32_t SIGMA[4] = {0x61707865, 0x3320646E, 0x79622D32, 0x6B206574};

#define CHACHA20_BLOCK_SIZE 64

@interface ChaCha20Cipher (PrivateMethods)
- (void)setKey:(uint8_t*)key;
- (void)setIV:(uint8_t*)iv;
- (uint)uint8To32Little:(uint8_t*)buffer offset:(uint32_t)offset;
- (uint32_t)rotl:(uint32_t)x y:(uint32_t)y;
@end

@implementation ChaCha20Cipher

- (id)init:(NSData *)key iv:(NSData*)iv {
    self = [super init];
    if (self) {
        if ([key length] != 32) {
            @throw [NSException exceptionWithName:@"CryptoException" reason:@"Key length error" userInfo:nil];
        }
        if ([iv length] != 12) {
            @throw [NSException exceptionWithName:@"CryptoException" reason:@"IV length error" userInfo:nil];
        }
        
        [self setKey:(uint8_t *)key.bytes];
        [self setIV:(uint8_t *)iv.bytes];
        
        _index = 0;
    }
    return self;
}

- (uint32_t)getBlockSize {
    return CHACHA20_BLOCK_SIZE;
}

- (uint)uint8To32Little:(uint8_t *)buffer offset:(uint32_t)offset {
    return ((uint)buffer[offset] | ((uint)buffer[offset + 1] << 8) |
            ((uint)buffer[offset + 2] << 16) | ((uint)buffer[offset + 3] << 24));
}

- (uint32_t)rotl:(uint32_t)x y:(uint32_t)y {
    return (x<<y)|(x>>(32-y));
}

- (void)setKey:(uint8_t *)key {
    _state[4] = [self uint8To32Little:key offset:0];
    _state[5] = [self uint8To32Little:key offset:4];
    _state[6] = [self uint8To32Little:key offset:8];
    _state[7] = [self uint8To32Little:key offset:12];
    
    _state[8] = [self uint8To32Little:key offset:16];
    _state[9] = [self uint8To32Little:key offset:20];
    _state[10] = [self uint8To32Little:key offset:24];
    _state[11] = [self uint8To32Little:key offset:28];
    
    _state[0] = SIGMA[0];
    _state[1] = SIGMA[1];
    _state[2] = SIGMA[2];
    _state[3] = SIGMA[3];
}

- (void)setIV:(uint8_t *)iv {
    _state[12] = 0;
    _state[13] = [self uint8To32Little:iv offset:0];
    _state[14] = [self uint8To32Little:iv offset:4];
    _state[15] = [self uint8To32Little:iv offset:8];
}

- (void)reset {
    _state[8] = 0;
    _state[9] = 0;
    _index = 0;
}

- (void)NextBlock:(uint8_t*)buf {
    uint32_t x[16];
    
    for (int i=0; i<16; i++) {
        x[i] = _state[i];
    }
    
    for (int i = 0; i < 10; i++) {
        // Column quarter rounds
        x[ 0] += x[ 4];
        x[12] = [self rotl:(x[12] ^ x[ 0]) y:16];
        x[ 8] += x[12];
        x[ 4] = [self rotl:(x[ 4] ^ x[ 8]) y:12];
        x[ 0] += x[ 4];
        x[12] = [self rotl:(x[12] ^ x[ 0]) y:8];
        x[ 8] += x[12];
        x[ 4] = [self rotl:(x[ 4] ^ x[ 8]) y:7];
        
        x[ 1] += x[ 5];
        x[13] = [self rotl:(x[13] ^ x[ 1]) y:16];
        x[ 9] += x[13];
        x[ 5] = [self rotl:(x[ 5] ^ x[ 9]) y:12];
        x[ 1] += x[ 5];
        x[13] = [self rotl:(x[13] ^ x[ 1]) y:8];
        x[ 9] += x[13];
        x[ 5] = [self rotl:(x[ 5] ^ x[ 9]) y:7];
        
        x[ 2] += x[ 6];
        x[14] = [self rotl:(x[14] ^ x[ 2]) y:16];
        x[10] += x[14];
        x[ 6] = [self rotl:(x[ 6] ^ x[10]) y:12];
        x[ 2] += x[ 6];
        x[14] = [self rotl:(x[14] ^ x[ 2]) y:8];
        x[10] += x[14];
        x[ 6] = [self rotl:(x[ 6] ^ x[10]) y:7];
        
        x[ 3] += x[ 7];
        x[15] = [self rotl:(x[15] ^ x[ 3]) y:16];
        x[11] += x[15];
        x[ 7] = [self rotl:(x[ 7] ^ x[11]) y:12];
        x[ 3] += x[ 7];
        x[15] = [self rotl:(x[15] ^ x[ 3]) y:8];
        x[11] += x[15];
        x[ 7] = [self rotl:(x[ 7] ^ x[11]) y:7];

        // Diagonal quarter rounds
        x[ 0] += x[ 5];
        x[15] = [self rotl:(x[15] ^ x[ 0]) y:16];
        x[10] += x[15];
        x[ 5] = [self rotl:(x[ 5] ^ x[10]) y:12];
        x[ 0] += x[ 5];
        x[15] = [self rotl:(x[15] ^ x[ 0]) y:8];
        x[10] += x[15];
        x[ 5] = [self rotl:(x[ 5] ^ x[10]) y:7];
        
        x[ 1] += x[ 6];
        x[12] = [self rotl:(x[12] ^ x[ 1]) y:16];
        x[11] += x[12];
        x[ 6] = [self rotl:(x[ 6] ^ x[11]) y:12];
        x[ 1] += x[ 6];
        x[12] = [self rotl:(x[12] ^ x[ 1]) y:8];
        x[11] += x[12];
        x[ 6] = [self rotl:(x[ 6] ^ x[11]) y:7];

        x[ 2] += x[ 7];
        x[13] = [self rotl:(x[13] ^ x[ 2]) y:16];
        x[ 8] += x[13];
        x[ 7] = [self rotl:(x[ 7] ^ x[ 8]) y:12];
        x[ 2] += x[ 7];
        x[13] = [self rotl:(x[13] ^ x[ 2]) y:8];
        x[ 8] += x[13];
        x[ 7] = [self rotl:(x[ 7] ^ x[ 8]) y:7];
        
        x[ 3] += x[ 4];
        x[14] = [self rotl:(x[14] ^ x[ 3]) y:16];
        x[ 9] += x[14];
        x[ 4] = [self rotl:(x[ 4] ^ x[ 9]) y:12];
        x[ 3] += x[ 4];
        x[14] = [self rotl:(x[14] ^ x[ 3]) y:8];
        x[ 9] += x[14];
        x[ 4] = [self rotl:(x[ 4] ^ x[ 9]) y:7];
    }
    
    for (int i = 0; i < 16; i++) {
        x[i] += _state[i];
    }
    
    for (int i = 0, j = 0; i < 16; i++, j +=4 ) {
        uint32_t t = x[i];
        buf[j+0] = (uint8_t)t;
        buf[j+1] = (uint8_t)(t >> 8);
        buf[j+2] = (uint8_t)(t >> 16);
        buf[j+3] = (uint8_t)(t >> 24);
    }
    
    _state[12]++;
    if (!_state[12]) {
        _state[13]++;
    }
}

-(void)seek:(uint32_t) pos {
    _state[12] = (uint32_t) pos >> 6;
    [self invalidateBlock];
}

@end
