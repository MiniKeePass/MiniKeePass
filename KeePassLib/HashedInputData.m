//
//  HashedInputData.m
//  KeePass2
//
//  Created by Qiang Yu on 1/31/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <CommonCrypto/CommonDigest.h>
#import "HashedInputData.h"
#import "Kdb.h"
#import "Utils.h"

@interface HashedInputData (PrivateMethods)
-(BOOL)readBlock;
@end


@implementation HashedInputData
@synthesize _dataSource;

#pragma mark -
#pragma mark alloc/dealloc

-(id)initWithDataSource:(id<InputDataSource>)input{
	if(self=[super init]){
		self._dataSource = input;
		_eof = NO;
	}
	return self;
}

-(void)dealloc{
	[_block release];
	[_dataSource release];
	[super dealloc];
}

#pragma mark -
#pragma mark Private Methods
//
// read a block
// return YES if more to read; otherwise NO
//
-(BOOL)readBlock {
	if(_eof) return NO;
	
	if([Utils readInt32LE:_dataSource]!=_blockIndex){
		@throw [NSException exceptionWithName:@"InvalidData" reason:@"InvalidBlockIndex" userInfo:nil];
	}
	_blockIndex++;	
	
	// read the hash
	uint8_t hash[32];
	if([_dataSource readBytes:hash length:32]!=32){
		@throw [NSException exceptionWithName:@"InvalidData" reason:@"InvalidBlockHashSize" userInfo:nil];
	}
	
	// read the block
	uint32_t blockSize = [Utils readInt32LE:_dataSource];
	
	if(blockSize < 0){
		@throw [NSException exceptionWithName:@"InvalidData" reason:@"InvalidBlockSize" userInfo:nil];
	}
	
	if(blockSize){
		if(_block) [_block release];		
		_block = [[ByteBuffer alloc ]initWithSize:blockSize];
		
				
		if([_dataSource readBytes:_block._bytes length:blockSize]!=blockSize){
			@throw [NSException exceptionWithName:@"InvalidData" reason:@"InvalidBlock" userInfo:nil];
		}
		
		// verify the hashcode
		uint8_t result[32];
		CC_SHA256(_block._bytes, blockSize, result);
		if(memcmp(result, hash, 32))
			@throw [NSException exceptionWithName:@"InvalidData" reason:@"InvalidBlockHash" userInfo:nil];
		
		return YES;
	}else{ //end of block
		_eof = YES;
		
		[_block release];
		_block = nil;
		
		for(int i=0; i<32; i++){
			if(hash[i]) 
				@throw [NSException exceptionWithName:@"InvalidData" reason:@"InvalidBlockHash" userInfo:nil];
		}
		
		return NO;
	}
}

#pragma mark -
#pragma mark InputDataSource Protocol
-(NSUInteger)readBytes:(void *)buffer length:(NSUInteger)length{
	if(_eof) return 0;
	NSUInteger remaining = length; //number of remaining bytes to read
	NSUInteger bufferOffset = 0;
	while (remaining>0) {
		if(_block == nil || _blockOffset == _block._size){
			_blockOffset = 0;
			if(![self readBlock]){
				return length - remaining;
			}
		}
				
		NSUInteger bytesToCopy = MIN(remaining, _block._size - _blockOffset);

		memcpy(buffer+bufferOffset, _block._bytes+_blockOffset, bytesToCopy);
		
		_blockOffset+=bytesToCopy; bufferOffset+=bytesToCopy;remaining -= bytesToCopy;
	}
	return length;
}

-(NSUInteger)lengthOfRemainingReadbleBytes{
	@throw [NSException exceptionWithName:@"UnsupportedMethod" reason:@"UnsupportedMethod" userInfo:nil];
}

-(NSUInteger)setReadOffset:(NSUInteger) offset{
	@throw [NSException exceptionWithName:@"UnsupportedMethod" reason:@"UnsupportedMethod" userInfo:nil];
}

-(NSUInteger)moveReadOffset:(NSInteger) offset{
	@throw [NSException exceptionWithName:@"UnsupportedMethod" reason:@"UnsupportedMethod" userInfo:nil];
}

@end
