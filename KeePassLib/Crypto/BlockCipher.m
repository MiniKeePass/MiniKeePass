//
//  BlockCipher.m
//  KeePassLib
//
//  Created by tssmith on 3/28/17.
//  Copyright 2017. All rights reserved.
//

#import "BlockCipher.h"

@interface BlockCipher (PrivateMethods)
- (void)xor:(void*)pb dpos:(size_t)dpos len:(size_t)len;
@end

@implementation BlockCipher

- (id) init {
    blockSize = [self getBlockSize];
    if( blockSize <= 0 ) return nil;
    blockBuf = malloc( blockSize );
    if( blockBuf == nil ) return nil;
    blockPos = blockSize;
    
    return self;
}

- (uint32_t) getBlockSize {
    [self doesNotRecognizeSelector:_cmd];
    return 0;
}

- (void)NextBlock:(uint8_t*)buf {
    [self doesNotRecognizeSelector:_cmd];
}

-(void) invalidateBlock {
    blockPos = blockSize;
}

-(void) Encrypt:(NSMutableData *)m {
    [self Encrypt:m.mutableBytes iOffset:0 count:[m length]];
}

-(void) Encrypt:(void*)m iOffset:(size_t)iOffset count:(size_t)cb  {
    
    if( m == nil ) {
        @throw [NSException exceptionWithName:@"CryptoException" reason:@"Bad Ptr" userInfo:nil];
    }
    if( cb == 0 ) {
        @throw [NSException exceptionWithName:@"CryptoException" reason:@"Bad count" userInfo:nil];
    }
    if( iOffset > cb ) {
        @throw [NSException exceptionWithName:@"CryptoException" reason:@"Bad Offset" userInfo:nil];
    }
    
    uint32_t cbBlock = blockSize;
    
    while(cb > 0)
    {
        if( blockPos == cbBlock)
        {
            [self NextBlock:blockBuf];
            blockPos = 0;
        }
        
        size_t cbCopy = MIN(cbBlock - blockPos, cb);
        
        [self xor:m dpos:iOffset len:cbCopy ];
        
        blockPos += cbCopy;
        iOffset += cbCopy;
        cb -= cbCopy;
    }
}

-(void) Decrypt:(NSMutableData *)m {
    [self Encrypt:m];
}

-(void) Decrypt:(void *)m iOffset:(size_t)iOffset count:(size_t)cb {
    [self Encrypt:m  iOffset:iOffset count:cb];
}

- (void)xor:(void*)pb dpos:(size_t)dpos len:(size_t)len {
    uint8_t *bytes = (uint8_t*)pb;
    
    for (size_t i = 0; i < len; i++) {
        bytes[dpos + i] ^= blockBuf[blockPos + i];
    }
}

@end
