//
//  Kdb4Node.h
//  KeePass2
//
//  Created by Qiang Yu on 2/23/10.
//  Copyright 2010 Qiang Yu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Kdb.h"

#define KDB4_PRE_SIG1 (0x9AA2D903)
#define KDB4_PRE_SIG2 (0xB54BFB66)
#define KDB4_SIG1 (0x9AA2D903)
#define KDB4_SIG2 (0xB54BFB67)

#define KDB4_VERSION (0x00030000)

#define HEADER_EOH 0
#define HEADER_COMMENT 1
#define HEADER_CIPHERID 2
#define HEADER_COMPRESSION 3
#define HEADER_MASTERSEED 4
#define HEADER_TRANSFORMSEED 5
#define HEADER_TRANSFORMROUNDS 6
#define HEADER_ENCRYPTIONIV 7
#define HEADER_PROTECTEDKEY 8
#define HEADER_STARTBYTES 9
#define HEADER_RANDOMSTREAMID 10

#define COMPRESSION_NONE 0
#define COMPRESSION_GZIP 1
#define COMPRESSION_COUNT 2

#define CSR_NONE        0
#define CSR_ARC4VARIANT 1
#define CSR_SALSA20     2
#define CSR_COUNT       3

@interface Kdb4Group : KdbGroup

@property(nonatomic, readonly) NSMutableDictionary *properties;
@property(nonatomic, assign) BOOL expires;
@property(nonatomic, assign) NSUInteger usageCount;
@property(nonatomic, retain) NSDate *locationChanged;

@end


@interface StringField : NSObject

@property(nonatomic, copy) NSString *key;
@property(nonatomic, copy) NSString *value;
@property(nonatomic, assign) BOOL protected;

- (id)initWithKey:(NSString *)key andValue:(NSString *)value;

@end


@interface Kdb4Entry : KdbEntry

@property(nonatomic, readonly) NSMutableDictionary *properties;
@property(nonatomic, readonly) NSMutableArray *stringFields;
@property(nonatomic, assign) BOOL expires;
@property(nonatomic, assign) NSUInteger usageCount;
@property(nonatomic, retain) NSDate *locationChanged;

@end


@interface Kdb4Tree : KdbTree

@property(nonatomic, readonly) NSMutableDictionary *properties;
@property(nonatomic, assign) uint64_t rounds;
@property(nonatomic, assign) uint32_t compressionAlgorithm;

@end
