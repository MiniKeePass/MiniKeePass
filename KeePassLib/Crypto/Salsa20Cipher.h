//
//  Salsa20Cipher.h
//  KeePassLib
//
//  Created by tssmith on 3/28/17.
//  Copyright 2017. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BlockCipher.h"

@interface Salsa20Cipher : BlockCipher {
    uint32_t _state[16];
    uint32_t _index;
/*
 uint8_t _keyStream[64];
*/
}

// - (id)init;
// - (id)init:(NSData*)key;
- (id)init:(NSData*)key iv:(NSData*)iv;

@end
