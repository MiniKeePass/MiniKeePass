//
//  BinaryDateContainer.h
//  KeePass2
//
//  Created by Qiang Yu on 2/16/10.
//  Copyright 2010 Qiang Yu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ByteBuffer.h"

@protocol BinaryContainer<NSObject>
-(void)storeBinary:(id<InputDataSource>)buffer size:(uint32_t)size;
-(uint8_t *)getBinary;
-(uint32_t)getSize;
@end

/*
 * MemoryBinaryContainer saves binary data in the memory
 */

@interface MemoryBinaryContainer : NSObject<BinaryContainer>
{
	ByteBuffer * _buffer;
}

@end

