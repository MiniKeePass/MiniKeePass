//
//  KdbReaderFactory.m
//  KeePass2
//
//  Created by Qiang Yu on 3/8/10.
//  Copyright 2010 Qiang Yu. All rights reserved.
//

#import "KdbReaderFactory.h"
#import "Kdb3Reader.h"
#import "Kdb4Reader.h"
#import "Utils.h"

#define KDB3_SIG1 (0x9AA2D903)
#define KDB3_SIG2 (0xB54BFB65)

#define KDB4_PRE_SIG1 (0x9AA2D903)
#define KDB4_PRE_SIG2 (0xB54BFB66)

#define KDB4_SIG1 (0x9AA2D903)
#define KDB4_SIG2 (0xB54BFB67)


@implementation KdbReaderFactory

/*
 * This function checks the signature of the input stream, and returns
 * appropriate KdbReader instance;
 * The caller is the owner of the reader returned, and should release it after use;
 * This function returns nil if the signatures are unknown
 *
 * The way to use this class and KDB reader is:
   id<KdbReader> read = [KdbReaderFactory newKdbReader:input];
   [read load:input withPassword:password];
   [read release];
 */
+(id<KdbReader>)newKdbReader:(WrapperNSData *)input{
	uint32_t signature1 = [Utils readInt32LE:input];
	uint32_t signature2 = [Utils readInt32LE:input];
	
	if(signature1==KDB3_SIG1&&signature2==KDB3_SIG2){
		return [[Kdb3Reader alloc] init];
	}
	
	if(signature1==KDB4_SIG1&&signature2==KDB4_SIG2){
		return [[Kdb4Reader alloc]init];
	}
		
	if(signature1==KDB4_PRE_SIG1&&signature2==KDB4_PRE_SIG2){
		return [[Kdb4Reader alloc]init];
	}
	
	@throw [NSException exceptionWithName:@"Unsupported" reason:@"UnsupportedVersion" userInfo:nil];
}

@end
