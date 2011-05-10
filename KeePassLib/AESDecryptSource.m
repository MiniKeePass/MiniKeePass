//
//  AESInputSource.m
//  KeePass2
//
//  Created by Qiang Yu on 2/16/10.
//  Copyright 2010 Qiang Yu. All rights reserved.
//

#import "AESDecryptSource.h"
#import "ByteBuffer.h"

@interface AESDecryptSource(PrivateMethods)
-(BOOL)decrypt;
@end

@implementation AESDecryptSource
@synthesize _source;

// the byte size of input source must be multiples of 16 
-(id)initWithInputSource:(id<InputDataSource>)source Keys:(uint8_t *)keys andIV:(uint8_t *)iv{
	if(self=[super init]){
		self._source = source;
		_cryptorRef = nil; _bufferOffset = 0;
		_bufferSize = 0; _eof = NO;
		
		CCCryptorCreate(kCCDecrypt, kCCAlgorithmAES128, kCCOptionPKCS7Padding, keys, kCCKeySizeAES256, iv, &_cryptorRef);
	}
	
	return self;
}

-(void)dealloc{
	CCCryptorRelease(_cryptorRef);		
	[_source release];
	[super dealloc];
}

-(BOOL)decrypt{	
	if(_eof) return NO;
	_bufferOffset = 0;
	_bufferSize = 0;
	NSUInteger read = [_source readBytes:_inputBuffer length:AES_BUFFERSIZE];
	
	size_t movedBytes=0;
	CCCryptorStatus cs;
	if(read){
		if(cs=CCCryptorUpdate(_cryptorRef, _inputBuffer, read, _outputBuffer, AES_BUFFERSIZE, &movedBytes)){
			//DLog(@"error here1 %d", cs);
			@throw [NSException exceptionWithName:@"DecryptError" reason:@"DecryptError" userInfo:nil];
		};	
				
		_bufferSize += movedBytes;	
	}	
	
	if(read<AES_BUFFERSIZE){
		if(cs=CCCryptorFinal(_cryptorRef, _outputBuffer+movedBytes, AES_BUFFERSIZE-movedBytes, &movedBytes)){
			DLog(@"error here2 %d", cs);
			@throw [NSException exceptionWithName:@"DecryptError" reason:@"DecryptError" userInfo:nil];
		}	
		
		_eof = YES;
		_bufferSize += movedBytes;			
	}	

	return YES;
}

#pragma mark -
#pragma mark InputDataSource Protocol
-(NSUInteger)readBytes:(void *)buffer length:(NSUInteger)length{
	NSUInteger remaining = length; //number of remaining bytes to read
	NSUInteger offset = 0;
	
	while (remaining>0) {
		if(_bufferOffset >= _bufferSize){
			if(![self decrypt]){
				return length - remaining;
			}
		}
		
		//DLog(@"offset & size %d %d %d", _bufferSize, _bufferOffset, remaining);
		
		NSUInteger bytesToCopy = MIN(remaining, _bufferSize - _bufferOffset);		
		memcpy((uint8_t *)buffer+offset, _outputBuffer+_bufferOffset, bytesToCopy);
		
		_bufferOffset+=bytesToCopy; offset+=bytesToCopy;remaining -= bytesToCopy;
	}
	return length;	
}

-(NSUInteger)lengthOfRemainingReadbleBytes{
	@throw [NSException exceptionWithName:@"UnsupportedMethod" reason:@"lengthOfRemainingReadbleBytes" userInfo:nil];
}

-(NSUInteger)setReadOffset:(NSUInteger) offset{
	@throw [NSException exceptionWithName:@"UnsupportedMethod" reason:@"setReadOffset" userInfo:nil];
}

-(NSUInteger)moveReadOffset:(NSInteger) offset{
	//DLog(@"offset %d", offset);
	if(offset<0)
		@throw [NSException exceptionWithName:@"UnsupportedMethod" reason:@"moveReadOffset" userInfo:nil];
	else{
		ByteBuffer * b = [[ByteBuffer alloc]initWithSize:offset dataSource:self];
		[b release];
	}
	return 0;
}

@end
