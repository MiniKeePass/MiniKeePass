//
//  WrapperNSData.m
//  KeePass2
//
//  Created by Qiang Yu on 1/10/10.
//  Copyright 2010 Qiang Yu. All rights reserved.
//

#import "WrapperNSData.h"


@implementation WrapperNSData
-initWithContentsOfMappedFile:(NSString *)filename{
	if(self=[super init]){
		_nsdata = [[NSData alloc]initWithContentsOfMappedFile:filename];
	}
	return self;
}

-initWithNSData:(NSData *)data{
	if(self=[super init]){
		_nsdata = [data retain];
	}
	return self;
}

-(void)dealloc{
	[_nsdata dealloc];
	[super dealloc];
}

-(NSUInteger)readBytes:(void *)buffer length:(NSUInteger)length{
	NSRange range;
	range.location = _offset;
	range.length = MIN([_nsdata length]-_offset, length);
	if(range.length) [_nsdata getBytes:buffer range:range];
	_offset += range.length;
	return range.length;
}


-(NSUInteger)lengthOfRemainingReadbleBytes{
	return [_nsdata length]-_offset;
}

-(uint8_t *)getRemainingBufferToRead{
	return (uint8_t *)[_nsdata bytes]+_offset;
}

 
-(NSUInteger)setReadOffset:(NSUInteger) offset{
	if(offset>[_nsdata length]) offset=[_nsdata length];
	_offset = offset;
	return _offset;
}


-(NSUInteger)moveReadOffset:(NSInteger) offset{
	[self setReadOffset:_offset+offset];
	return _offset;
}

@end
