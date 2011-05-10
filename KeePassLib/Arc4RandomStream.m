//
//  Arc4RandomStream.m
//  KeePass2
//
//  Created by Qiang Yu on 2/28/10.
//  Copyright 2010 Qiang Yu. All rights reserved.
//

#import "Arc4RandomStream.h"
#import "ByteBuffer.h"

@interface Arc4RandomStream (PrivateMethods)
-(void)updateState;
@end


@implementation Arc4RandomStream

//-(id)init:(uint8_t *)key len:(uint32_t)len input:(id<InputDataSource>)source {
-(id)init:(uint8_t *)key len:(uint32_t)len{
	_i = _j = 0;
	if(self = [super init]){
		uint32_t index = 0;
		for (uint32_t w = 0; w < 256; w++)
			_state[w] = (uint8_t)(w & 0xff);
		
		int i = 0, j = 0;
		uint8_t t = 0;
		
		for (uint32_t w = 0; w < 256; w++){
			j += ((_state[w] + key[index]));
			j &= 0xff;
			
			t = _state[i]; 
			_state[i] = _state[j];
			_state[j] = t;
			
			++index;
			if (index >= len)
				index = 0;
		}
		
		[self updateState];
		_index = 512; //skip first 512 bytes
		
		//self._source = source;
	}
	return self;
}

-(void)dealloc{
	//[_source release];
	[super dealloc];
}

-(void)updateState{
	uint8_t t = 0;
	for (uint32_t w = 0; w < ARC_BUFFER_SIZE; w++) {
		++_i;
		_i &= 0xff;
		_j += _state[_i];
		_j &= 0xff;
		
		t = _state[_i]; 
		_state[_i] = _state[_j];
		_state[_j] = (uint8_t) (t & 0xff);
		
		t = (uint8_t) (_state[_i] + _state[_j]);
		_buffer[w] = _state[t & 0xff];
	}
}

-(NSString *)xor:(NSData *)data{
	ByteBuffer * bb = [[ByteBuffer alloc]initWithSize:[data length]];	
	[data getBytes:bb._bytes length:bb._size];
	
	for(int i=0; i<bb._size; i++){
		if(_index==0) [self updateState];				
		(bb._bytes)[i] ^= _buffer[_index];
		_index = (_index+1)&ARC_BUFFER_SIZE;			
	}
	
	NSString * rv = [[NSString alloc]initWithBytes:bb._bytes length:bb._size encoding:NSUTF8StringEncoding];
	[bb release];
	return [rv autorelease];
}

/* 
 * remove the support of InputSource protocol to make the class less confusing
 *
 
 -(NSUInteger)readBytes:(void *)buffer length:(NSUInteger)length{
 NSUInteger read = [_source readBytes:buffer length:length];
 
 for(int i=0; i<read; i++){
 if(_index==0) [self updateState];				
 ((uint8_t *)buffer)[i] ^= _buffer[_index];
 _index = (_index+1)&ARC_BUFFER_SIZE;
 }	
 
 return read;
 }
 
 -(NSUInteger)lengthOfRemainingReadbleBytes{
	@throw [NSException exceptionWithName:@"UnsupportedMethod" reason:@"lengthOfRemainingReadbleBytes" userInfo:nil];
}

-(NSUInteger)setReadOffset:(NSUInteger) offset{
	@throw [NSException exceptionWithName:@"UnsupportedMethod" reason:@"setReadOffset" userInfo:nil];
}

-(NSUInteger)moveReadOffset:(NSInteger) offset{
	@throw [NSException exceptionWithName:@"UnsupportedMethod" reason:@"moveReadOffset" userInfo:nil];
}
*/
@end
