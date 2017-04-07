//
//  Utils.h
//  KeePass2
//
//  Created by Qiang Yu on 1/7/10.
//  Copyright 2010 Qiang Yu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "InputStream.h"

#define VARIANT_DICT_TYPE_UINT32      0x04
#define VARIANT_DICT_TYPE_UINT64      0x05
#define VARIANT_DICT_TYPE_BOOL        0x08
#define VARIANT_DICT_TYPE_INT32       0x0C
#define VARIANT_DICT_TYPE_INT64       0x0D
#define VARIANT_DICT_TYPE_STRING      0x18
#define VARIANT_DICT_TYPE_BYTEARRAY   0x42

@interface Utils : NSObject {
}

+ (BOOL)emptyString:(NSString*)str;

+ (NSData*)randomBytes:(uint32_t)length;

+ (NSString*)hexDumpData:(NSData*)data;
+ (NSString*)hexDumpBytes:(const void *)buffer length:(ssize_t)length;

+ (NSData*)getUInt64Bytes:(uint64_t)val;
+ (NSData*)getUInt32Bytes:(uint32_t)val;

+ (uint64_t)BytesToInt64:(NSData*)data;
@end

@interface VariantDictionary : NSObject {
    NSMutableDictionary *dict;
    NSMutableDictionary *type;
}

-(id) init;

- (void)addObject:(id)obj forKey:(id <NSCopying>)key objtype:(uint32_t)objtype;
- (id)objectForKeyedSubscript:(id)key;

-(void) deserialize:(InputStream*)data;
-(NSData*) serialize;
-(NSUInteger)count;

@end
