//
//  Salsa20RandomStream.h
//  KeePass2
//
//  Created by Qiang Yu on 2/28/10.
//  Copyright 2010 Qiang Yu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DataSource.h"
#import "RandomStream.h"

@interface Salsa20RandomStream : NSObject <RandomStream> {
    uint32_t _state[16];
    uint32_t _index;
    uint8_t _keyStream[64];
}

- (id)init:(NSData*)key;

@end
