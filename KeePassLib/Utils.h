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

+ (uint64_t)BytesToInt64:(NSData*)data;
@end

@interface VariantDictionary : NSObject {
    NSMutableDictionary *dict;
    NSMutableDictionary *type;
}

-(id) init;

- (id)objectForKeyedSubscript:(id)key;

- (void)addUInt32:(uint32_t)value forKey:(NSString*)key;
- (void)addUInt64:(uint64_t)value forKey:(NSString*)key;
- (void)addBool:(BOOL)value forKey:(NSString*)key;
- (void)addInt32:(int32_t)value forKey:(NSString*)key;
- (void)addInt64:(int64_t)value forKey:(NSString*)key;
- (void)addString:(NSString*)string forKey:(NSString*)key;
- (void)addByteArray:(NSData*)data forKey:(NSString*)key;

-(void) deserialize:(InputStream*)data;
-(NSData*) serialize;
-(NSUInteger)count;

@end
