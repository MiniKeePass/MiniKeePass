//
//  Arc4RandomStream.m
//  KeePass2
//
//  Created by Qiang Yu on 2/28/10.
//  Copyright 2010 Qiang Yu. All rights reserved.
//

#import "Arc4RandomStream.h"
#import <Security/Security.h>

@interface Arc4RandomStream (PrivateMethods)
- (void)updateState;
@end

@implementation Arc4RandomStream

- (id)init {
    uint8_t buffer[256];
    
    SecRandomCopyBytes(kSecRandomDefault, sizeof(buffer), buffer);
    
    return [self init:[NSData dataWithBytes:buffer length:sizeof(buffer)]];
}

- (id)init:(NSData*)key {
    self = [super init];
    if (self) {
        const uint8_t *bytes = key.bytes;
        NSUInteger length = key.length;

        _i = 0;
        _j = 0;

        uint32_t index = 0;
        for (uint32_t w = 0; w < 256; w++) {
            _state[w] = (uint8_t)(w & 0xff);
        }
        
        int i = 0, j = 0;
        uint8_t t = 0;
        
        for (uint32_t w = 0; w < 256; w++) {
            j += ((_state[w] + bytes[index]));
            j &= 0xff;
            
            t = _state[i]; 
            _state[i] = _state[j];
            _state[j] = t;
            
            ++index;
            if (index >= length) {
                index = 0;
            }
        }
        
        [self updateState];
        _index = 512; //skip first 512 bytes
    }
    return self;
}

- (void)dealloc {
    [super dealloc];
}

- (void)updateState {
    uint8_t t = 0;
    for (uint32_t w = 0; w < ARC_BUFFER_SIZE; w++) {
        ++_i;
        _i &= 0xff;
        _j += _state[_i];
        _j &= 0xff;
        
        t = _state[_i]; 
        _state[_i] = _state[_j];
        _state[_j] = (uint8_t) (t & 0xff);
        
        t = (uint8_t) (_state[_i] + _state[_j]);
        _buffer[w] = _state[t & 0xff];
    }
}

- (uint8_t)getByte {
    uint8_t value;
    
    if (_index == 0) {
        [self updateState];
    }
    
    value = _buffer[_index];

    _index = (_index + 1) & ARC_BUFFER_SIZE;
    
    return value;
}

@end
