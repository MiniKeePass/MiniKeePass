//
//  Kdb4Node.h
//  KeePass2
//
//  Created by Qiang Yu on 2/23/10.
//  Copyright 2010 Qiang Yu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Kdb.h"
#import "UUID.h"

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

@property(nonatomic, retain) UUID *uuid;
@property(nonatomic, copy) NSString *notes;
@property(nonatomic, assign) BOOL isExpanded;
@property(nonatomic, copy) NSString *defaultAutoTypeSequence;
@property(nonatomic, copy) NSString *enableAutoType;
@property(nonatomic, copy) NSString *enableSearching;
@property(nonatomic, retain) UUID *lastTopVisibleEntry;
@property(nonatomic, assign) BOOL expires;
@property(nonatomic, assign) NSInteger usageCount;
@property(nonatomic, retain) NSDate *locationChanged;

@end


@interface StringField : NSObject

@property(nonatomic, copy) NSString *key;
@property(nonatomic, copy) NSString *value;
@property(nonatomic, assign) BOOL protected;

- (id)initWithKey:(NSString *)key andValue:(NSString *)value;

@end


@interface Binary : NSObject

@property(nonatomic, assign) NSInteger binaryId;
@property(nonatomic, assign) BOOL compressed;
@property(nonatomic, retain) NSString *data;

@end


@interface BinaryRef : NSObject

@property(nonatomic, retain) NSString *key;
@property(nonatomic, assign) NSInteger ref;

@end


@interface Association : NSObject

@property(nonatomic, copy) NSString *window;
@property(nonatomic, copy) NSString *keystrokeSequence;

@end


@interface AutoType : NSObject

@property(nonatomic, assign) BOOL enabled;
@property(nonatomic, assign) NSInteger dataTransferObfuscation;
@property(nonatomic, readonly) NSMutableArray *associations;

@end


@interface Kdb4Entry : KdbEntry

@property(nonatomic, retain) UUID *uuid;
@property(nonatomic, copy) NSString *foregroundColor;
@property(nonatomic, copy) NSString *backgroundColor;
@property(nonatomic, copy) NSString *overrideUrl;
@property(nonatomic, copy) NSString *tags;
@property(nonatomic, assign) BOOL expires;
@property(nonatomic, assign) NSInteger usageCount;
@property(nonatomic, retain) NSDate *locationChanged;
@property(nonatomic, readonly) NSMutableArray *stringFields;
@property(nonatomic, readonly) NSMutableArray *binaries;
@property(nonatomic, retain) AutoType *autoType;

@end


@interface Kdb4Tree : KdbTree

@property(nonatomic, assign) uint64_t rounds;
@property(nonatomic, assign) uint32_t compressionAlgorithm;

@property(nonatomic, copy) NSString *generator;
@property(nonatomic, copy) NSString *databaseName;
@property(nonatomic, retain) NSDate *databaseNameChanged;
@property(nonatomic, copy) NSString *databaseDescription;
@property(nonatomic, retain) NSDate *databaseDescriptionChanged;
@property(nonatomic, copy) NSString *defaultUserName;
@property(nonatomic, retain) NSDate *defaultUserNameChanged;
@property(nonatomic, assign) NSInteger maintenanceHistoryDays;
@property(nonatomic, copy) NSString *color;
@property(nonatomic, retain) NSDate *masterKeyChanged;
@property(nonatomic, assign) NSInteger masterKeyChangeRec;
@property(nonatomic, assign) NSInteger masterKeyChangeForce;
@property(nonatomic, assign) BOOL protectTitle;
@property(nonatomic, assign) BOOL protectUserName;
@property(nonatomic, assign) BOOL protectPassword;
@property(nonatomic, assign) BOOL protectUrl;
@property(nonatomic, assign) BOOL protectNotes;
@property(nonatomic, assign) BOOL recycleBinEnabled;
@property(nonatomic, retain) UUID *recycleBinUuid;
@property(nonatomic, retain) NSDate *recycleBinChanged;
@property(nonatomic, retain) UUID *entryTemplatesGroup;
@property(nonatomic, retain) NSDate *entryTemplatesGroupChanged;
@property(nonatomic, assign) NSInteger historyMaxItems;
@property(nonatomic, assign) NSInteger historyMaxSize;
@property(nonatomic, retain) UUID *lastSelectedGroup;
@property(nonatomic, retain) UUID *lastTopVisibleGroup;
@property(nonatomic, readonly) NSMutableArray *binaries;

@end
