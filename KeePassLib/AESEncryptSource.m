//
//  AESEncryptSource.m
//  KeePass2
//
//  Created by Qiang Yu on 2/21/10.
//  Copyright 2010 Qiang Yu. All rights reserved.
//

#import "AESEncryptSource.h"
#import "ByteBuffer.h"

@implementation AESEncryptSource
@synthesize _data;

-(id)init:(uint8_t *)keys andIV:(uint8_t *)iv{
	if(self=[super init]){
		_cryptorRef = nil; 
		CCCryptorCreate(kCCEncrypt, kCCAlgorithmAES128, kCCOptionPKCS7Padding, keys, kCCKeySizeAES256, iv, &_cryptorRef);
		CC_SHA256_Init(&_shaCtx);
	}
	
	return self;
}

-(void)dealloc{
	CCCryptorRelease(_cryptorRef);	
	[_data release];
	[super dealloc];
}

-(void)setData:(NSMutableData *)data{
	if(_data!=data){
		[_data release];
		_data = [data retain];
		_initDataLen = [data length];
	}
}

-(void)update:(void *)buffer size:(uint32_t)size{
	size_t length = CCCryptorGetOutputLength(_cryptorRef, size, NO);
	
	ByteBuffer * bb = nil;
	
	uint8_t * b = nil;
	uint32_t s = 64;
	
	//DLog(@"length-->%d", length);
	
	if(length<=64){
		b = _buffer;
	}else{
		bb = [[ByteBuffer alloc] initWithSize:size+32];
		b = bb._bytes;
		s = bb._size;
	}
	
	CC_SHA256_Update(&_shaCtx, buffer, size);

	@try{
		size_t movedBytes = 0;
		CCCryptorStatus cs;		
		if(cs=CCCryptorUpdate(_cryptorRef, buffer, size, b, s, &movedBytes)){
			@throw [NSException exceptionWithName:@"EncryptError" reason:@"EncryptError" userInfo:nil];
		};
		[_data appendBytes:b length:movedBytes];
		_updatedBytes += size;
	}@finally {
		[bb release];
	}
}

-(void)final{
	size_t length = CCCryptorGetOutputLength(_cryptorRef, _updatedBytes, YES);
	uint32_t size = length - [_data length] + _initDataLen;
	
	//DLog(@"final length-->%d", size);
	
	ByteBuffer * bb = nil;
	
	uint8_t * b = nil;
	uint32_t s = 64;
	
	if(size<=64){
		b = _buffer;
	}else{
		bb = [[ByteBuffer alloc] initWithSize:size];
		b = bb._bytes;
		s = bb._size;
	}
	
	CC_SHA256_Final(_hash, &_shaCtx);
	
	@try{
		size_t movedBytes = 0;
		CCCryptorStatus cs;	
		if(cs=CCCryptorFinal(_cryptorRef, b, s, &movedBytes)){
			@throw [NSException exceptionWithName:@"EncryptError" reason:@"EncryptError" userInfo:nil];			
		}
		[_data appendBytes:b length:movedBytes];
	}@finally {
		[bb release];
	}
}

-(uint8_t *)getHash{
	return _hash;
}

@end
