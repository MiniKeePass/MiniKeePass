//
//  Kdb3Persist.m
//  KeePass2
//
//  Created by Qiang Yu on 2/16/10.
//  Copyright 2010 Qiang Yu. All rights reserved.
//

#import "Kdb3Writer.h"
#import "Kdb3Node.h"
#import "Stack.h"
#import "Utils.h"
#import "AESEncryptSource.h"
#import "Kdb3Persist.h"

#define DEFAULT_BIN_SIZE (32*1024)

@interface Kdb3Writer(PrivateMethods)
-(uint32_t) numOfGroups:(Kdb3Group *) root;
-(uint32_t) numOfEntries:(Kdb3Group *)root;
-(void) initKdbPassword;
-(void) writeHeader:(Kdb3Group *)root to:(NSMutableData *)data;
@end


@implementation Kdb3Writer

/**
 * Get the number of groups in the KDB tree, including the %ROOT% node 
 * although it will not be persisted
 */
-(uint32_t)numOfGroups:(Kdb3Group *) root {
	int num = 0;
	for(Kdb3Group * g in root._subGroups){
		num+=[self numOfGroups:g];
	}
	return num+1;
}

/**
 * Get the total number of entries and meta entries in the KDB tree
 *
 */
-(uint32_t)numOfEntries:(Kdb3Group *)root{
	int num = [root._entries count] + [root._metaEntries count];
	for(Kdb3Group * g in root._subGroups){
		num+=[self numOfEntries:g];
	}
	return num;
}

/**
 * Init the Kdb password:
 * 1. randomly generate 32 bytes transform seed
 * 2. randomly generate 16 bytes master seed
 * 3. set the default round to 600
 */
-(void) initKdbPassword{
	ByteBuffer * transformSeed = [[ByteBuffer alloc]initWithSize:32];
	uint8_t * ts = transformSeed._bytes;
	
	*((uint32_t *)&ts[0]) = arc4random(); *((uint32_t *)&ts[4]) = arc4random();
	*((uint32_t *)&ts[8]) = arc4random(); *((uint32_t *)&ts[12]) = arc4random();
	*((uint32_t *)&ts[16]) = arc4random(); *((uint32_t *)&ts[20]) = arc4random();
	*((uint32_t *)&ts[24]) = arc4random(); *((uint32_t *)&ts[28]) = arc4random();
	
	ByteBuffer * masterSeed = [[ByteBuffer alloc]initWithSize:16];
	ts = masterSeed._bytes;
	
	*((uint32_t *)&ts[0]) = arc4random(); *((uint32_t *)&ts[4]) = arc4random();
	*((uint32_t *)&ts[8]) = arc4random(); *((uint32_t *)&ts[12]) = arc4random();
	
	_password = [[KdbPassword alloc]init];
	_password._masterSeed = masterSeed;
	_password._transformSeed = transformSeed;
	_password._rounds = 600;
	
	[masterSeed release];
	[transformSeed release];
}

/**
 * Write the KDB3 header
 *
 */
-(void) writeHeader:(Kdb3Group *)root to:(NSMutableData *)data{
	//Version, Flags & Version
	*((uint32_t *)(_header)) = SWAP_INT32_HOST_TO_LE(KDB3_SIG1);   //0..3
	*((uint32_t *)(_header+4)) = SWAP_INT32_HOST_TO_LE(KDB3_SIG2); //4..7
	*((uint32_t *)(_header+8)) = SWAP_INT32_HOST_TO_LE(FLAG_SHA2|FLAG_RIJNDAEL); //8..11
	*((uint32_t *)(_header+12)) = SWAP_INT32_HOST_TO_LE(KDB3_VER); //12..15
	
	memcpy(_header+16, _password._masterSeed._bytes, 16); //16..31
	memcpy(_header+32, _encryptionIV, 16);  //32..47
	
	uint32_t numGroups = [self numOfGroups:root]-1; //minus the root itself
	uint32_t numEntries = [self numOfEntries:root];	
	
	DLog(@"-->found  %d entries", numEntries);
	
	*((uint32_t *)(_header+48)) = SWAP_INT32_HOST_TO_LE(numGroups); //48..51
	*((uint32_t *)(_header+52)) = SWAP_INT32_HOST_TO_LE(numEntries); //52..55		
	
	//56..87 content hash
	
	memcpy(_header+88, _password._transformSeed._bytes, 32); //88..119
	*((uint32_t *)(_header+120)) = SWAP_INT32_HOST_TO_LE(_password._rounds); //120..123	
	[data appendBytes:_header length:KDB3_HEADER_SIZE]; 
}

/**
 * Persist a tree into a file, using the specified password
 */
-(void)persist:(id<KdbTree>)tree file:(NSString *) fileName withPassword:(NSString *)password{
	[self initKdbPassword];	

	*((uint32_t *)&_encryptionIV[0]) = arc4random(); *((uint32_t *)&_encryptionIV[4]) = arc4random();
	*((uint32_t *)&_encryptionIV[8]) = arc4random(); *((uint32_t *)&_encryptionIV[12]) = arc4random();		
	ByteBuffer * finalKey = [_password createFinalKey32ForPasssword:password coding:NSWindowsCP1252StringEncoding kdbVersion:3];
	
	//write the header
	NSMutableData * data = [[NSMutableData alloc]initWithCapacity:DEFAULT_BIN_SIZE];
	[self writeHeader:(Kdb3Group *)[tree getRoot] to:data];
	
	AESEncryptSource * enc = [[AESEncryptSource alloc] init:finalKey._bytes andIV:_encryptionIV];
	enc._data = data;
	[data release];
	[finalKey release];	

	Kdb3Persist * persist = nil;
	
	@try{
		persist = [[Kdb3Persist alloc]initWithTree:tree andDest:enc];
		[persist persist];
		NSRange range;
		range.location = 56;
		range.length = 32;
		//backfill the content hash
		[enc._data replaceBytesInRange:range withBytes:[enc getHash]];
		if(![enc._data writeToFile:fileName atomically:YES]){
			@throw [NSException exceptionWithName:@"IOError" reason:@"WriteFile" userInfo:nil];
		}
	}@finally {
		[persist release];
		[enc release];
	}
}


-(void)newFile:(NSString *)fileName withPassword:(NSString *)password{
	Kdb3Tree * tree = [Kdb3Tree newTree];
	[self persist:tree file:fileName withPassword:password];
	[tree release];
	
}

@end
