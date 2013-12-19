//
//  Salsa20RandomStream.h
//  KeePass2
//
//  Created by Qiang Yu on 2/28/10.
//  Copyright 2010 Qiang Yu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RandomStream.h"

@interface Salsa20RandomStream : RandomStream {
    uint32_t _state[16];
    uint32_t _index;
    uint8_t _keyStream[64];
}

- (id)init;
- (id)init:(NSData*)key;

@end
