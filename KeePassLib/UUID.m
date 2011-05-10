//
//  UUID.m
//  KeePass2
//
//  Created by Qiang Yu on 1/2/10.
//  Copyright 2010 Qiang Yu. All rights reserved.
//

#import "UUID.h"

static UUID * _AES_UUID;

@implementation UUID

-(id)init{
	if(self=[super initWithSize:16]){
		CFUUIDRef uuidref = CFUUIDCreate(kCFAllocatorDefault);
		CFUUIDBytes bytes = CFUUIDGetUUIDBytes(uuidref);
		memcpy(_bytes, &bytes, 16);
		CFRelease(uuidref);	
	}
	return self;
}

-(NSString *)description{
	NSString * descr = [NSString stringWithFormat:@"%02X%02X%02X%02X-%02X%02X-%02X%02X-%02X%02X-%02X%02X%02X%02X%02X%02X", 
							_bytes[0], _bytes[1], _bytes[2], _bytes[3],
							_bytes[4], _bytes[5],
							_bytes[6], _bytes[7],
							_bytes[8], _bytes[9],
							_bytes[10], _bytes[11], _bytes[12], _bytes[13], _bytes[14], _bytes[15]];
	return descr;
}

//AES algorithm UUID
+(UUID*)getAESUUID{
	@synchronized(self){
		if(!_AES_UUID){
			_AES_UUID = [[UUID alloc]initWithSize:16];
			_AES_UUID._bytes[0]=0x31; _AES_UUID._bytes[1]=0xC1;
			_AES_UUID._bytes[2]=0xF2; _AES_UUID._bytes[3]=0xE6;
			_AES_UUID._bytes[4]=0xBF; _AES_UUID._bytes[5]=0x71;
			_AES_UUID._bytes[6]=0x43; _AES_UUID._bytes[7]=0x50;
			_AES_UUID._bytes[8]=0xBE; _AES_UUID._bytes[9]=0x58;
			_AES_UUID._bytes[10]=0x05; _AES_UUID._bytes[11]=0x21;
			_AES_UUID._bytes[12]=0x6A; _AES_UUID._bytes[13]=0xFC;
			_AES_UUID._bytes[14]=0x5A; _AES_UUID._bytes[15]=0xFF;
		}
	}
	DLog(@"%@", _AES_UUID);
	return _AES_UUID;
}

@end
