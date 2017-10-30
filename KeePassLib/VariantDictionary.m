/*
 * Copyright 2017 Jason Rush and John Flanagan. All rights reserved.
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#import "VariantDictionary.h"
#import "Utils.h"

#define VARIANT_DICT_VERSION       0x0100

#define VARIANT_DICT_TYPE_UINT32      0x04
#define VARIANT_DICT_TYPE_UINT64      0x05
#define VARIANT_DICT_TYPE_BOOL        0x08
#define VARIANT_DICT_TYPE_INT32       0x0C
#define VARIANT_DICT_TYPE_INT64       0x0D
#define VARIANT_DICT_TYPE_STRING      0x18
#define VARIANT_DICT_TYPE_BYTEARRAY   0x42

#define VARIANT_DICT_EOH              0x00

@implementation VariantDictionary

- (id)init {
    self = [super init];
    if (self) {
        dict = [[NSMutableDictionary alloc] init];
        type = [[NSMutableDictionary alloc] init];
    }
    
    return self;
}

- (void)addObject:(id)obj forKey:(id <NSCopying>)key objtype:(uint32_t)objtype {
    dict[key] = obj;
    type[key] = [NSNumber numberWithUnsignedInteger:objtype];
}

- (id)objectForKeyedSubscript:(id)key {
    return dict[key];
}

- (void)addUInt32:(uint32_t)value forKey:(NSString*)key {
    NSNumber *num = [[NSNumber alloc] initWithUnsignedInt:value];
    [self addObject:num forKey:key objtype:VARIANT_DICT_TYPE_UINT32];
}

- (void)addUInt64:(uint64_t)value forKey:(NSString*)key {
    NSNumber *num = [[NSNumber alloc] initWithUnsignedLongLong:value];
    [self addObject:num forKey:key objtype:VARIANT_DICT_TYPE_UINT64];
}

- (void)addBool:(BOOL)value forKey:(NSString*)key {
    NSNumber *num = [[NSNumber alloc] initWithBool:value];
    [self addObject:num forKey:key objtype:VARIANT_DICT_TYPE_BOOL];
    
}
- (void)addInt32:(int32_t)value forKey:(NSString*)key {
    NSNumber *num = [[NSNumber alloc] initWithUnsignedLongLong:value];
    [self addObject:num forKey:key objtype:VARIANT_DICT_TYPE_INT32];
    
}
- (void)addInt64:(int64_t)value forKey:(NSString*)key {
    NSNumber *num = [[NSNumber alloc] initWithUnsignedLongLong:value];
    [self addObject:num forKey:key objtype:VARIANT_DICT_TYPE_INT64];
    
}
- (void)addString:(NSString*)string forKey:(NSString*)key {
    [self addObject:string forKey:key objtype:VARIANT_DICT_TYPE_STRING];
    
}
- (void)addByteArray:(NSData*)data forKey:(NSString*)key {
    [self addObject:data forKey:key objtype:VARIANT_DICT_TYPE_BYTEARRAY];
}

- (NSUInteger)count {
    return [dict count];
}

- (void)deserialize:(InputStream*)inputStream {
    uint16_t paramVersion = [inputStream readInt16];
    paramVersion = CFSwapInt16LittleToHost(paramVersion);
    if ((paramVersion & 0xFF00) > VARIANT_DICT_VERSION) {
        @throw [NSException exceptionWithName:@"InvalidParameterField" reason:@"BadVersion" userInfo:nil];
    }
    
    while (1) {
        uint8_t valueType = [inputStream readInt8];
        if (valueType == VARIANT_DICT_EOH) break;
        uint32_t keyNameLength = [inputStream readInt32];
        keyNameLength = CFSwapInt32LittleToHost( keyNameLength );
        NSString *keyName = [inputStream readString:keyNameLength encoding:NSASCIIStringEncoding];
        uint32_t valueLength =[inputStream readInt32];
        valueLength = CFSwapInt32LittleToHost( valueLength );
        
        uint32_t pvalu32;
        uint64_t pvalu64;
        uint8_t pvalbyte;
        int32_t pvali32;
        int64_t pvali64;
        
        switch (valueType) {
            case VARIANT_DICT_TYPE_UINT32:
                pvalu32 = [inputStream readInt32];
                dict[keyName] = [NSNumber numberWithUnsignedInteger:pvalu32];
                type[keyName] = [NSNumber numberWithUnsignedInteger:VARIANT_DICT_TYPE_UINT32];
                break;
            case VARIANT_DICT_TYPE_UINT64:
                pvalu64 = [inputStream readInt64];
                dict[keyName] = [NSNumber numberWithUnsignedLongLong:pvalu64];
                type[keyName] = [NSNumber numberWithUnsignedInteger:VARIANT_DICT_TYPE_UINT64];
                break;
            case VARIANT_DICT_TYPE_BOOL:
                pvalbyte = [inputStream readInt8];
                dict[keyName] = [NSNumber numberWithChar:pvalbyte];
                type[keyName] = [NSNumber numberWithUnsignedInteger:VARIANT_DICT_TYPE_BOOL];
                break;
            case VARIANT_DICT_TYPE_INT32:
                pvali32 = [inputStream readInt32];
                dict[keyName] = [NSNumber numberWithInteger:pvali32];
                type[keyName] = [NSNumber numberWithUnsignedInteger:VARIANT_DICT_TYPE_INT32];
                break;
            case VARIANT_DICT_TYPE_INT64:
                pvali64 = [inputStream readInt64];
                dict[keyName] = [NSNumber numberWithLongLong:pvali64];
                type[keyName] = [NSNumber numberWithUnsignedInteger:VARIANT_DICT_TYPE_INT64];
                break;
            case VARIANT_DICT_TYPE_STRING:
                dict[keyName] = [inputStream readString:valueLength encoding:NSASCIIStringEncoding];
                type[keyName] = [NSNumber numberWithUnsignedInteger:VARIANT_DICT_TYPE_STRING];
                break;
            case VARIANT_DICT_TYPE_BYTEARRAY:
                dict[keyName] = [inputStream readData:valueLength];
                type[keyName] = [NSNumber numberWithUnsignedInteger:VARIANT_DICT_TYPE_BYTEARRAY];
                break;
            default:
                @throw [NSException exceptionWithName:@"InvalidParameterField" reason:@"BadFieldType" userInfo:nil];
        }
    }
}

- (void)appendByte:(NSMutableData*)arr byte:(uint8_t)byte {
    uint8_t buf[1];
    
    buf[0] = byte;
    [arr appendBytes:buf length:1];
}

- (NSData*)serialize {
    uint32_t keylen;
    NSMutableData *serData = [[NSMutableData alloc] init];
    
    [serData appendData:[Utils getUInt16Bytes:VARIANT_DICT_VERSION]];
    
    for (NSString *key in dict) {
        NSObject *item = dict[key];
        if ([item isKindOfClass:[NSNumber class]]) {
            NSNumber *num = (NSNumber *)item;
            uint32_t num_type = (uint32_t)[(NSNumber*)type[key] unsignedIntegerValue];
            if (num_type == VARIANT_DICT_TYPE_UINT64) {
                [self appendByte:serData byte:VARIANT_DICT_TYPE_UINT64];
                keylen = (uint32_t)[key length];
                [serData appendData:[Utils getUInt32Bytes:keylen]];
                [serData appendBytes:[key cStringUsingEncoding:NSASCIIStringEncoding] length:keylen];
                [serData appendData:[Utils getUInt32Bytes:8]];
                [serData appendData:[Utils getUInt64BytesFromNumber:num]];
            } else if (num_type == VARIANT_DICT_TYPE_UINT32) {
                [self appendByte:serData byte:VARIANT_DICT_TYPE_UINT32];
                keylen = (uint32_t)[key length];
                [serData appendData:[Utils getUInt32Bytes:keylen]];
                [serData appendBytes:[key cStringUsingEncoding:NSASCIIStringEncoding] length:keylen];
                [serData appendData:[Utils getUInt32Bytes:4]];
                [serData appendData:[Utils getUInt32BytesFromNumber:num]];
            } else if (num_type == VARIANT_DICT_TYPE_BOOL) {
                [self appendByte:serData byte:VARIANT_DICT_TYPE_BOOL];
                keylen = (uint32_t)[key length];
                [serData appendData:[Utils getUInt32Bytes:keylen]];
                [serData appendBytes:[key cStringUsingEncoding:NSASCIIStringEncoding] length:keylen];
                [serData appendData:[Utils getUInt32Bytes:1]];
                uint8_t byte = [num unsignedCharValue];
                [serData appendBytes:&byte length:1];
            } else if (num_type == VARIANT_DICT_TYPE_INT64) {
                [self appendByte:serData byte:VARIANT_DICT_TYPE_INT64];
                keylen = (uint32_t)[key length];
                [serData appendData:[Utils getUInt32Bytes:keylen]];
                [serData appendBytes:[key cStringUsingEncoding:NSASCIIStringEncoding] length:keylen];
                [serData appendData:[Utils getUInt32Bytes:8]];
                [serData appendData:[Utils getUInt64BytesFromNumber:num]];
            } else if (num_type == VARIANT_DICT_TYPE_INT32) {
                [self appendByte:serData byte:VARIANT_DICT_TYPE_INT32];
                keylen = (uint32_t)[key length];
                [serData appendData:[Utils getUInt32Bytes:keylen]];
                [serData appendBytes:[key cStringUsingEncoding:NSASCIIStringEncoding] length:keylen];
                [serData appendData:[Utils getUInt32Bytes:4]];
                [serData appendData:[Utils getUInt32BytesFromNumber:num]];
            } else {
                printf("Obj-C type(%d)\n", num_type );
                @throw [NSException exceptionWithName:@"InvalidParameterField" reason:@"NotImplemented" userInfo:nil];
            }
        } else if ([item isKindOfClass:[NSString class]]) {
            NSString *str = (NSString *)item;
            [self appendByte:serData byte:VARIANT_DICT_TYPE_STRING];
            keylen = (uint32_t)[key length];
            [serData appendData:[Utils getUInt32Bytes:keylen]];
            [serData appendBytes:[key cStringUsingEncoding:NSASCIIStringEncoding] length:keylen];
            [serData appendData:[Utils getUInt32Bytes:(uint32_t)[str length]]];
            [serData appendBytes:[str cStringUsingEncoding:NSASCIIStringEncoding] length:[str length]];
        } else if ([item isKindOfClass:[NSData class]]) {
            NSData *data = (NSData *)item;
            [self appendByte:serData byte:VARIANT_DICT_TYPE_BYTEARRAY];
            keylen = (uint32_t)[key length];
            [serData appendData:[Utils getUInt32Bytes:keylen]];
            [serData appendBytes:[key cStringUsingEncoding:NSASCIIStringEncoding] length:keylen];
            [serData appendData:[Utils getUInt32Bytes:(uint32_t)[data length]]];
            [serData appendData:data];
        } else {
            @throw [NSException exceptionWithName:@"Unknown Class Object" reason:@"Serialization Error" userInfo:nil];
        }
    }
    
    [self appendByte:serData byte:VARIANT_DICT_EOH];

    return serData;
}

@end
