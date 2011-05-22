//
//  Utils.m
//  KeePass2
//
//  Created by Qiang Yu on 1/7/10.
//  Copyright 2010 Qiang Yu. All rights reserved.
//

#import "Utils.h"


@implementation Utils

+ (uint8_t)readInt8LE:(id<InputDataSource>)ds {
    uint8_t value;
    [ds readBytes:(uint8_t *)(&value) length:1];
    return (value);
}

+ (uint16_t)readInt16LE:(id<InputDataSource>)ds {
    uint16_t value;
    [ds readBytes:(uint8_t *)(&value) length:2];
    return CFSwapInt16LittleToHost(value);
}

+ (uint32_t)readInt32LE:(id<InputDataSource>)ds {
    uint32_t value;
    [ds readBytes:(uint8_t *)(&value) length:4];
    return CFSwapInt32LittleToHost(value);
}

+ (uint64_t)readInt64LE:(id<InputDataSource>)ds {
    uint64_t value;
    [ds readBytes:(uint8_t *)(&value) length:8];
    return CFSwapInt64LittleToHost(value);
}


+ (BOOL)emptyString:(NSString*)str{
    return (!str || ![str length]);
}

+ (void)getRandomBytes:(uint8_t*)buffer length:(uint32_t)length {
    uint32_t *ptr = (uint32_t*)buffer;
    uint32_t i;
    
    length = length / 4;
    for (i = 0; i < length; i++) {
        *ptr++ = arc4random(); // FIXME TODO
    }
}

@end
