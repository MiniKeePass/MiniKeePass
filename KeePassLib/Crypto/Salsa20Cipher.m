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

#import "Salsa20Cipher.h"
#import <CommonCrypto/CommonDigest.h>
#import <Security/Security.h>

static uint32_t SIGMA[4] = {0x61707865, 0x3320646E, 0x79622D32, 0x6B206574};

#define SALSA20_BLOCK_SIZE 64

@interface Salsa20Cipher (PrivateMethods)
- (void)setKey:(uint8_t*)key;
- (void)setIV:(uint8_t*)iv;
- (uint)uint8To32Little:(uint8_t*)buffer offset:(uint32_t)offset;
- (uint32_t)rotl:(uint32_t)x y:(uint32_t)y;
@end

@implementation Salsa20Cipher

- (id)init:(NSData *)key iv:(NSData*)iv {
    self = [super init];
    if (self) {
        if ([key length] != 32) {
            @throw [NSException exceptionWithName:@"CryptoException" reason:@"Key length error" userInfo:nil];
        }
        if ([iv length] < 8) {
            @throw [NSException exceptionWithName:@"CryptoException" reason:@"IV length error" userInfo:nil];
        }
        
        [self setKey:(uint8_t *)key.bytes];
        [self setIV:(uint8_t *)iv.bytes];
        
        _index = 0;
    }
    return self;
}

- (uint32_t)getBlockSize {
    return SALSA20_BLOCK_SIZE;
}

- (uint)uint8To32Little:(uint8_t *)buffer offset:(uint32_t)offset {
    return ((uint)buffer[offset] | ((uint)buffer[offset + 1] << 8) |
            ((uint)buffer[offset + 2] << 16) | ((uint)buffer[offset + 3] << 24));
}

- (uint32_t)rotl:(uint32_t)x y:(uint32_t)y {
    return (x<<y)|(x>>(32-y));
}

- (void)setKey:(uint8_t *)key {
    _state[1] = [self uint8To32Little:key offset:0];
    _state[2] = [self uint8To32Little:key offset:4];
    _state[3] = [self uint8To32Little:key offset:8];
    _state[4] = [self uint8To32Little:key offset:12];
    
    _state[11] = [self uint8To32Little:key offset:16];
    _state[12] = [self uint8To32Little:key offset:20];
    _state[13] = [self uint8To32Little:key offset:24];
    _state[14] = [self uint8To32Little:key offset:28];
    _state[0 ] = SIGMA[0];
    _state[5 ] = SIGMA[1];
    _state[10] = SIGMA[2];
    _state[15] = SIGMA[3];
}

- (void)setIV:(uint8_t *)iv {
    _state[6] = [self uint8To32Little:iv offset:0];
    _state[7] = [self uint8To32Little:iv offset:4];
    _state[8] = 0;
    _state[9] = 0;
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
        x[ 4] ^= [self rotl:(x[ 0]+x[12]) y:7];
        x[ 8] ^= [self rotl:(x[ 4]+x[ 0]) y:9];
        x[12] ^= [self rotl:(x[ 8]+x[ 4]) y:13];
        x[ 0] ^= [self rotl:(x[12]+x[ 8]) y:18];
        x[ 9] ^= [self rotl:(x[ 5]+x[ 1]) y:7];
        x[13] ^= [self rotl:(x[ 9]+x[ 5]) y:9];
        x[ 1] ^= [self rotl:(x[13]+x[ 9]) y:13];
        x[ 5] ^= [self rotl:(x[ 1]+x[13]) y:18];
        x[14] ^= [self rotl:(x[10]+x[ 6]) y:7];
        x[ 2] ^= [self rotl:(x[14]+x[10]) y:9];
        x[ 6] ^= [self rotl:(x[ 2]+x[14]) y:13];
        x[10] ^= [self rotl:(x[ 6]+x[ 2]) y:18];
        x[ 3] ^= [self rotl:(x[15]+x[11]) y:7];
        x[ 7] ^= [self rotl:(x[ 3]+x[15]) y:9];
        x[11] ^= [self rotl:(x[ 7]+x[ 3]) y:13];
        x[15] ^= [self rotl:(x[11]+x[ 7]) y:18];
        x[ 1] ^= [self rotl:(x[ 0]+x[ 3]) y:7];
        x[ 2] ^= [self rotl:(x[ 1]+x[ 0]) y:9];
        x[ 3] ^= [self rotl:(x[ 2]+x[ 1]) y:13];
        x[ 0] ^= [self rotl:(x[ 3]+x[ 2]) y:18];
        x[ 6] ^= [self rotl:(x[ 5]+x[ 4]) y:7];
        x[ 7] ^= [self rotl:(x[ 6]+x[ 5]) y:9];
        x[ 4] ^= [self rotl:(x[ 7]+x[ 6]) y:13];
        x[ 5] ^= [self rotl:(x[ 4]+x[ 7]) y:18];
        x[11] ^= [self rotl:(x[10]+x[ 9]) y:7];
        x[ 8] ^= [self rotl:(x[11]+x[10]) y:9];
        x[ 9] ^= [self rotl:(x[ 8]+x[11]) y:13];
        x[10] ^= [self rotl:(x[ 9]+x[ 8]) y:18];
        x[12] ^= [self rotl:(x[15]+x[14]) y:7];
        x[13] ^= [self rotl:(x[12]+x[15]) y:9];
        x[14] ^= [self rotl:(x[13]+x[12]) y:13];
        x[15] ^= [self rotl:(x[14]+x[13]) y:18];
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
    
    _state[8]++; 
    if (!_state[8]) {
        _state[9]++;
    }
}

@end
