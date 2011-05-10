//
//  BinaryDateContainer.m
//  KeePass2
//
//  Created by Qiang Yu on 2/16/10.
//  Copyright 2010 Qiang Yu. All rights reserved.
//

#import "BinaryContainer.h"


@implementation MemoryBinaryContainer
#pragma mark alloc/dealloc
-(void)dealloc{
	[_buffer release];
	[super dealloc];
}

-(void)storeBinary:(id<InputDataSource>)source size:(uint32_t)size{
	if(!_buffer){
		_buffer = [[ByteBuffer alloc] initWithSize:size dataSource:source];
	}
}

-(uint8_t *)getBinary{
	return _buffer._bytes;
}

-(uint32_t)getSize{
	if(_buffer)
		return _buffer._size;
	return 0;
}
@end
