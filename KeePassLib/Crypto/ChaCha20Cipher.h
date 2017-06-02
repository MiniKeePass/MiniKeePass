//
//  ChaCha20Cipher.h
//  KeePassLib
//
//  Created by tssmith on 3/28/17.
//  Copyright 2017. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BlockCipher.h"

@interface ChaCha20Cipher : BlockCipher {
    uint32_t _state[16];
    uint32_t _index;
}

- (id)init:(NSData*)key iv:(NSData*)iv;
-(void)seek:(uint32_t) pos;

@end
