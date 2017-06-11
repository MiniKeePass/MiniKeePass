//
//  VariantDictionary.h
//  KeePassLib
//
//  Created by tssmith on 6/11/17.
//  Copyright 2017. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "InputStream.h"

@interface VariantDictionary : NSObject {
    NSMutableDictionary *dict;
    NSMutableDictionary *type;
}

- (id)init;

- (id)objectForKeyedSubscript:(id)key;

- (void)addUInt32:(uint32_t)value forKey:(NSString*)key;
- (void)addUInt64:(uint64_t)value forKey:(NSString*)key;
- (void)addBool:(BOOL)value forKey:(NSString*)key;
- (void)addInt32:(int32_t)value forKey:(NSString*)key;
- (void)addInt64:(int64_t)value forKey:(NSString*)key;
- (void)addString:(NSString*)string forKey:(NSString*)key;
- (void)addByteArray:(NSData*)data forKey:(NSString*)key;

- (void)deserialize:(InputStream*)data;
- (NSData*)serialize;
- (NSUInteger)count;

@end
