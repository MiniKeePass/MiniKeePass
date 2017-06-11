//
//  BlockCipher.h
//  KeePassLib
//
//  Created by tssmith on 3/28/17.
//  Copyright 2017. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BlockCipher : NSObject {
    uint8_t*  blockBuf;
    uint32_t  blockSize;
    uint32_t  blockPos;
}

- (id)init;
- (uint32_t)getBlockSize;
- (void)invalidateBlock;
- (void)NextBlock:(uint8_t*)buf;
- (void)Encrypt:(NSMutableData*)m;  // Use zero offset and whole length of m
- (void)Encrypt:(void*)pb iOffset:(size_t)iOffset count:(size_t)cb;

- (void)Decrypt:(NSMutableData*)m;
- (void)Decrypt:(void*)pb iOffset:(size_t)iOffset count:(size_t)cb;

@end
