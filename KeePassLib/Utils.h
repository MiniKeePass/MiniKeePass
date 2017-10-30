//
//  Utils.h
//  KeePass2
//
//  Created by Qiang Yu on 1/7/10.
//  Copyright 2010 Qiang Yu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "InputStream.h"

@interface Utils : NSObject {
}

+ (BOOL)emptyString:(NSString*)str;

+ (NSData*)randomBytes:(uint32_t)length;

+ (NSString*)hexDumpData:(NSData*)data;
+ (NSString*)hexDumpBytes:(const void *)buffer length:(ssize_t)length;

+ (NSData*)getUInt64Bytes:(uint64_t)val;
+ (NSData*)getUInt32Bytes:(uint32_t)val;
+ (NSData*)getUInt16Bytes:(uint32_t)val;

+ (NSData*)getUInt64BytesFromNumber:(NSNumber *)num;
+ (NSData*)getUInt32BytesFromNumber:(NSNumber *)num;

+ (uint64_t)BytesToInt64:(NSData*)data;

@end
