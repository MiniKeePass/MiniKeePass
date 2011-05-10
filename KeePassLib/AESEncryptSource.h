//
//  AESEncryptSource.h
//  KeePass2
//
//  Created by Qiang Yu on 2/21/10.
//  Copyright 2010 Qiang Yu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonCryptor.h>
#import <CommonCrypto/CommonDigest.h>

@interface AESEncryptSource : NSObject{
	NSMutableData * _data;
	CCCryptorRef _cryptorRef;
	uint32_t _updatedBytes;
	uint32_t _initDataLen;
	uint8_t _buffer[64];
	
	CC_SHA256_CTX _shaCtx;
	uint8_t _hash[32];
}

@property(nonatomic, retain, setter=setData) NSMutableData *  _data;

-(id)init:(uint8_t *)keys andIV:(uint8_t *)iv;
-(void)update:(void *)buffer size:(uint32_t)size;
-(void)final;
-(uint8_t *)getHash;

@end
