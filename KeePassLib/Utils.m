//
//  Utils.m
//  KeePass2
//
//  Created by Qiang Yu on 1/7/10.
//  Copyright 2010 Qiang Yu. All rights reserved.
//

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

@implementation Utils

+ (BOOL)emptyString:(NSString*)str{
    return (!str || ![str length]);
}

+ (NSData*)randomBytes:(uint32_t)length {
    uint8_t buffer[length];
    uint32_t *ptr = (uint32_t*)buffer;
    uint32_t n = length / 4;
    uint32_t i;
    
    for (i = 0; i < n; i++) {
        *ptr++ = arc4random();
    }
    
    return [NSData dataWithBytes:buffer length:length];
}

+ (NSString*)hexDumpData:(NSData*)data {
    return [self hexDumpBytes:data.bytes length:data.length];
}

+ (NSString*)hexDumpBytes:(const void *)buffer length:(ssize_t)length {
    NSMutableString *string = [[NSMutableString alloc] init];
    const uint8_t *bytes = (const uint8_t*)buffer;
    int i;
    int j;
    
    for (i = 0; i < length; i += 16) {
        // Print out the address
        [string appendFormat:@"%08X ", i];
        
        // Print out the hex
        for (j = 0; j < 16; j++) {
            int off = i + j;
            if (off < length) {
                // Print the hex digit
                [string appendFormat:@" %02X", bytes[off]];
            } else {
                // Pad out the last row
                [string appendString:@"   "];
            }
            
            // Add a space every 4 bytes
            if (((j + 1) % 4) == 0) {
                [string appendString:@" "];
            }
        }
        
        // Print out the ASCII
        [string appendString:@" |"];
        for (j = 0; j < 16; j++) {
            int off = i + j;
            if (off < length) {
                // Print the ASCII character
                unsigned char c = bytes[off];
                if (!isprint(c)) {
                    c = '.';
                }
                [string appendFormat:@"%c", c];
            } else {
                // Pad out the last row
                [string appendString:@" "];
            }
        }
        [string appendString:@"|\n"];
    }
    
    return string;
}

+ (NSData*)getUInt64BytesFromNumber:(NSNumber *)num {
    uint64_t val = [num unsignedLongLongValue];
    return [self getUInt64Bytes:val];
}

+ (NSData*)getUInt64Bytes:(uint64_t)val {  // Little Endian
    uint8_t buf[8];
    
    buf[0] = (uint8_t)val;
    buf[1] = (uint8_t) (val >> 8);
    buf[2] = (uint8_t) (val >> 16);
    buf[3] = (uint8_t) (val >> 24);
    buf[4] = (uint8_t) (val >> 32);
    buf[5] = (uint8_t) (val >> 40);
    buf[6] = (uint8_t) (val >> 48);
    buf[7] = (uint8_t) (val >> 56);
    
    return [[NSData alloc] initWithBytes:buf length:8];
}

+ (NSData*)getUInt32BytesFromNumber:(NSNumber *)num {
    uint32_t val = (uint32_t)[num unsignedIntegerValue];
    return [self getUInt32Bytes:val];
}

+ (NSData*)getUInt32Bytes:(uint32_t)val {
    uint8_t buf[4];
    
    buf[0] = (uint8_t)val;
    buf[1] = (uint8_t) (val >> 8);
    buf[2] = (uint8_t) (val >> 16);
    buf[3] = (uint8_t) (val >> 24);
    
    return [[NSData alloc] initWithBytes:buf length:4];
}

+ (NSData*)getUInt16Bytes:(uint32_t)val {
    uint8_t buf[2];
    
    buf[0] = (uint8_t)val;
    buf[1] = (uint8_t) (val >> 8);
    
    return [[NSData alloc] initWithBytes:buf length:2];
}

+ (uint64_t)BytesToInt64:(NSData*)data {
    uint8_t *pb;
    
    pb = (uint8_t *)data.bytes;
    
    return ((uint64_t)pb[0]         | ((uint64_t)pb[1] << 8)  | ((uint64_t)pb[2] << 16) |
            ((uint64_t)pb[3] << 24) | ((uint64_t)pb[4] << 32) | ((uint64_t)pb[5] << 40) |
            ((uint64_t)pb[6] << 48) | ((uint64_t)pb[7] << 56));
}

@end

@implementation VariantDictionary

-(id) init {
    
    dict = [[NSMutableDictionary alloc] init];
    type = [[NSMutableDictionary alloc] init];
    
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

-(void) deserialize:inputStream {
    uint16_t paramVersion = [inputStream readInt16];
    paramVersion = CFSwapInt16LittleToHost(paramVersion);
    if( (paramVersion & 0xFF00) > VARIANT_DICT_VERSION ) {
        @throw [NSException exceptionWithName:@"InvalidParameterField" reason:@"BadVersion" userInfo:nil];
    }
    
    while ( 1 ) {
        uint8_t valueType = [inputStream readInt8];
        if( valueType == VARIANT_DICT_EOH ) break;
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
        
        switch( valueType ) {
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

-(void) appendByte:(NSMutableData*)arr byte:(uint8_t)byte {
    uint8_t buf[1];
    
    buf[0] = byte;
    [arr appendBytes:buf length:1];
}

-(NSData*) serialize {
    uint32_t keylen;
    NSMutableData *serData = [[NSMutableData alloc] init];
    
    [serData appendData:[Utils getUInt16Bytes:VARIANT_DICT_VERSION]];
    
    for( NSString *key in dict ) {
        NSObject *item = dict[key];
        if( [item isKindOfClass:[NSNumber class]] ) {
            NSNumber *num = (NSNumber *)item;
            uint32_t num_type = (uint32_t)[(NSNumber*)type[key] unsignedIntegerValue];
            if( num_type == VARIANT_DICT_TYPE_UINT64 ) {
                [self appendByte:serData byte:VARIANT_DICT_TYPE_UINT64];
                keylen = (uint32_t)[key length];
                [serData appendData:[Utils getUInt32Bytes:keylen]];
                [serData appendBytes:[key cStringUsingEncoding:NSASCIIStringEncoding] length:keylen];
                [serData appendData:[Utils getUInt32Bytes:8]];
                [serData appendData:[Utils getUInt64BytesFromNumber:num]];
            } else if( num_type == VARIANT_DICT_TYPE_UINT32 ) {
                [self appendByte:serData byte:VARIANT_DICT_TYPE_UINT32];
                keylen = (uint32_t)[key length];
                [serData appendData:[Utils getUInt32Bytes:keylen]];
                [serData appendBytes:[key cStringUsingEncoding:NSASCIIStringEncoding] length:keylen];
                [serData appendData:[Utils getUInt32Bytes:4]];
                [serData appendData:[Utils getUInt32BytesFromNumber:num]];
            } else if( num_type == VARIANT_DICT_TYPE_BOOL ) {
                [self appendByte:serData byte:VARIANT_DICT_TYPE_BOOL];
                keylen = (uint32_t)[key length];
                [serData appendData:[Utils getUInt32Bytes:keylen]];
                [serData appendBytes:[key cStringUsingEncoding:NSASCIIStringEncoding] length:keylen];
                [serData appendData:[Utils getUInt32Bytes:1]];
                uint8_t byte = [num unsignedCharValue];
                [serData appendBytes:&byte length:1];
            } else if( num_type == VARIANT_DICT_TYPE_INT64 ) {
                [self appendByte:serData byte:VARIANT_DICT_TYPE_INT64];
                keylen = (uint32_t)[key length];
                [serData appendData:[Utils getUInt32Bytes:keylen]];
                [serData appendBytes:[key cStringUsingEncoding:NSASCIIStringEncoding] length:keylen];
                [serData appendData:[Utils getUInt32Bytes:8]];
                [serData appendData:[Utils getUInt64BytesFromNumber:num]];
            } else if( num_type == VARIANT_DICT_TYPE_INT32 ) {
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
        } else if( [item isKindOfClass:[NSString class]] ) {
            NSString *str = (NSString *)item;
            [self appendByte:serData byte:VARIANT_DICT_TYPE_STRING];
            keylen = (uint32_t)[key length];
            [serData appendData:[Utils getUInt32Bytes:keylen]];
            [serData appendBytes:[key cStringUsingEncoding:NSASCIIStringEncoding] length:keylen];
            [serData appendData:[Utils getUInt32Bytes:(uint32_t)[str length]]];
            [serData appendBytes:[str cStringUsingEncoding:NSASCIIStringEncoding] length:[str length]];
        } else if( [item isKindOfClass:[NSData class]] ) {
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
