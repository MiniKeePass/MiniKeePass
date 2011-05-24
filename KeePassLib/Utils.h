//
//  Utils.h
//  KeePass2
//
//  Created by Qiang Yu on 1/7/10.
//  Copyright 2010 Qiang Yu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ByteBuffer.h"

#define SWAP_INT16_LE_TO_HOST(X) (CFSwapInt16LittleToHost(*((uint16_t*)X))) 
#define SWAP_INT32_LE_TO_HOST(X) (CFSwapInt32LittleToHost(*((uint32_t*)X)))
#define SWAP_INT64_LE_TO_HOST(X) (CFSwapInt64LittleToHost(*((uint64_t*)X)))

#define SWAP_INT16_HOST_TO_LE(X) (CFSwapInt16HostToLittle(X))
#define SWAP_INT32_HOST_TO_LE(X) (CFSwapInt32HostToLittle(X))
#define SWAP_INT64_HOST_TO_LE(X) (CFSwapInt64HostToLittle(X))

@interface Utils : NSObject {
}

+ (uint8_t)readInt8LE:(id<InputDataSource>)ds;
+ (uint16_t)readInt16LE:(id<InputDataSource>)ds;
+ (uint32_t)readInt32LE:(id<InputDataSource>)ds;
+ (uint64_t)readInt64LE:(id<InputDataSource>)ds;

+ (BOOL)emptyString:(NSString*)str;

+ (NSData*)randomBytes:(uint32_t)length;

+ (NSString*)hexDumpData:(NSData*)data;
+ (NSString*)hexDumpBytes:(const void *)buffer length:(ssize_t)length;

@end
