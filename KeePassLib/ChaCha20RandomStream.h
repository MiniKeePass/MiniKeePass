//
//  ChaCha20RandomStream.h
//  KeePass2
//
//  Created by Qiang Yu on 2/28/10.
//  Copyright 2010 Qiang Yu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RandomStream.h"
#import "BlockCipher.h"

@interface ChaCha20RandomStream : RandomStream {
    BlockCipher *cipher;
}

- (id)init:(NSData*)key;

@end
