//
//  Utils.m
//  KeePass2
//
//  Created by Qiang Yu on 1/7/10.
//  Copyright 2010 Qiang Yu. All rights reserved.
//

#import "Utils.h"


@implementation Utils

+(ByteBuffer *) createByteBufferForString:(NSString *)string coding:(NSStringEncoding)encoding{
	NSUInteger size = [string lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
	ByteBuffer * result = [[ByteBuffer alloc] initWithSize:size];
	NSRange range;
	range.location = 0; range.length=[string length];
	[string getBytes:result._bytes maxLength:size usedLength:nil encoding:NSUTF8StringEncoding 
			 options:0 range:range remainingRange:nil];
	return result;
}

+(uint8_t)readInt8LE:(id<InputDataSource>) ds{
	uint8_t value;
	[ds readBytes:(uint8_t *)(&value) length:1];
	return (value);
}

+(uint16_t)readInt16LE:(id<InputDataSource>) ds{
	uint16_t value;
	[ds readBytes:(uint8_t *)(&value) length:2];
	return CFSwapInt16LittleToHost(value);
}

+(uint32_t)readInt32LE:(id<InputDataSource>) ds{
	uint32_t value;
	[ds readBytes:(uint8_t *)(&value) length:4];
	return CFSwapInt32LittleToHost(value);
}

+(uint64_t)readInt64LE:(id<InputDataSource>)ds{
	uint64_t value;
	[ds readBytes:(uint8_t *)(&value) length:8];
	return CFSwapInt64LittleToHost(value);
}


+(BOOL)emptyString:(NSString *)str{
	return (!str || ![str length]);
}

NSInteger EntrySort(id num1, id num2, void *context){
    int v1 = [num1 intValue];
    int v2 = [num2 intValue];
    if (v1 < v2)
        return NSOrderedAscending;
    else if (v1 > v2)
        return NSOrderedDescending;
    else
        return NSOrderedSame;
}

@end
