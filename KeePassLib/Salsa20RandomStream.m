//
//  Salsa20RandomStream.m
//  KeePass2
//
//  Created by Qiang Yu on 2/28/10.
//  Copyright 2010 Qiang Yu. All rights reserved.
//

#import "Salsa20RandomStream.h"
#import <CommonCrypto/CommonDigest.h>
#import <Security/Security.h>

static uint32_t SIGMA[4] = {0x61707865, 0x3320646E, 0x79622D32, 0x6B206574};

@interface Salsa20RandomStream (PrivateMethods)
- (void)setKey:(uint8_t*)key;
- (void)setIV:(uint8_t*)iv;
- (uint)uint8To32Little:(uint8_t*)buffer offset:(uint32_t)offset;
- (uint32_t)rotl:(uint32_t)x y:(uint32_t)y;
- (void)updateState;
@end

@implementation Salsa20RandomStream

- (id)init {
    uint8_t buffer[256];
    
    SecRandomCopyBytes(kSecRandomDefault, sizeof(buffer), buffer);
    
    return [self init:[NSData dataWithBytes:buffer length:sizeof(buffer)]];
}

- (id)init:(NSData*)key {
    self = [super init];
    if (self) {
        uint8_t key32[32];
        CC_SHA256(key.bytes, key.length, key32);
        [self setKey:key32];
        
        uint8_t iv[] = {0xE8, 0x30, 0x09, 0x4B, 0x97, 0x20, 0x5D, 0x2A};
        [self setIV:iv];
        
        _index = 0;
    }
    return self;
}

- (void)dealloc {
    [super dealloc];
}

- (uint)uint8To32Little:(uint8_t*)buffer offset:(uint32_t)offset {
    return ((uint)buffer[offset] | ((uint)buffer[offset + 1] << 8) |
            ((uint)buffer[offset + 2] << 16) | ((uint)buffer[offset + 3] << 24));
}

- (uint32_t)rotl:(uint32_t)x y:(uint32_t)y {
    return (x<<y)|(x>>(32-y));
}

- (void)setKey:(uint8_t*)key {
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

- (void)setIV:(uint8_t*)iv {
    _state[6] = [self uint8To32Little:iv offset:0];
    _state[7] = [self uint8To32Little:iv offset:4];
    _state[8] = 0;
    _state[9] = 0;
}

- (void)updateState {
    uint32_t x[16];
    
    for(int i=0; i<16; i++) x[i] = _state[i];
    
    for(int i=0; i<10; i++){
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
    
    for (int i = 0; i < 16; i++)
        x[i] += _state[i];
    
    for (int i = 0, j = 0; i < 16; i++, j +=4 ){
        uint32_t t = x[i];
        _keyStream[j+0] = (uint8_t)t;
        _keyStream[j+1] = (uint8_t)(t >> 8);
        _keyStream[j+2] = (uint8_t)(t >> 16);
        _keyStream[j+3] = (uint8_t)(t >> 24);
    }
    
    _state[8]++; 
    if (!_state[8]) {
        _state[9]++;
    }
}

- (uint8_t)getByte {
    uint8_t value;
    
    if (_index == 0) {
        [self updateState];
    }
    
    value = _keyStream[_index];
    
    _index = (_index + 1) & 0x3F;
    
    return value;
}

@end
