//
//  ByteBuffer.m
//  KeePass2
//
//  Created by Qiang Yu on 1/4/10.
//  Copyright 2010 Qiang Yu. All rights reserved.
//

#import "ByteBuffer.h"


@implementation ByteBuffer
@synthesize _bytes;
@synthesize _size;

-(id)initWithSize:(NSUInteger)size{
	if(self=[super init]){
		_size = size;
		_bytes = calloc(_size, 1);
	}
	return self;
}

-(id)initWithSize:(NSUInteger)size dataSource:(id<InputDataSource>)datasource{
	if([self initWithSize:size]){
		[datasource readBytes:_bytes length:_size];
	}
	return self;	
}

-(NSString *)description{
	NSMutableString * desc = [[NSMutableString alloc]initWithCapacity:_size];
	for(int i=0; i<_size; i++)
		[desc appendFormat:@"%02X ", _bytes[i]];
	return [desc autorelease];
}

-(void)dealloc{
	free(_bytes);
	[super dealloc];
}

- (NSUInteger)hash{
	NSUInteger result = 1;
	for(int i=0; i<_size; i++){
		result = 17*result + _bytes[i];
	}
	return result;
}

- (BOOL)isEqual:(id)anObject{
	if(self==anObject) return YES;
	if([anObject isKindOfClass:[ByteBuffer class]]&&((ByteBuffer *)anObject)._size==self._size){
		return memcmp(((ByteBuffer *)anObject)._bytes, self._bytes, _size)==0;
	}
	return NO;
}
@end
