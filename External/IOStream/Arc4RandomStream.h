//
//  Arc4RandomStream.h
//  KeePass2
//
//  Created by Qiang Yu on 2/28/10.
//  Copyright 2010 Qiang Yu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RandomStream.h"

#define ARC_BUFFER_SIZE 0x3FF

@interface Arc4RandomStream : RandomStream {
    uint8_t _state[256];
    uint32_t _i;
    uint32_t _j;
    
    uint8_t _buffer[ARC_BUFFER_SIZE]; //the size must be >= 512
    uint32_t _index;
}

- (id)init;
- (id)init:(NSData*)key;

@end
