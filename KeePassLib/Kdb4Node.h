/*
 * Copyright 2011-2012 Jason Rush and John Flanagan. All rights reserved.
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

#import <Foundation/Foundation.h>
#import "Kdb.h"
#import "VariantDictionary.h"
#import "UUID.h"

#define KDB4_SIG1              0x9AA2D903
#define KDB4_SIG2              0xB54BFB67
#define KDBX31_VERSION         0x00030001
#define KDBX40_VERSION         0x00040000

#define HEADER_EOH             0
#define HEADER_COMMENT         1
#define HEADER_CIPHERID        2
#define HEADER_COMPRESSION     3
#define HEADER_MASTERSEED      4
#define HEADER_TRANSFORMSEED   5
#define HEADER_TRANSFORMROUNDS 6
#define HEADER_ENCRYPTIONIV    7
#define HEADER_PROTECTEDKEY    8
#define HEADER_STARTBYTES      9
#define HEADER_RANDOMSTREAMID  10
#define HEADER_KDFPARMETERS    11
#define HEADER_PUBLICCUSTOM    12

#define INNER_HEADER_EOH              0
#define INNER_HEADER_RANDOMSTREAMID   1
#define INNER_HEADER_RANDOMSTREAMKEY  2
#define INNER_HEADER_BINARY           3

#define KDF_KEY_UUID_BYTES            @"$UUID"
#define KDF_AES_KEY_SEED              @"S"
#define KDF_AES_KEY_ROUNDS            @"R" /*uint64*/

#define KDF_ARGON2_KEY_SALT           @"S"
#define KDF_ARGON2_KEY_PARALLELISM    @"P" /*uint32*/
#define KDF_ARGON2_KEY_MEMORY         @"M" /*uint64*/
#define KDF_ARGON2_KEY_ITERATIONS     @"I" /*uint64*/
#define KDF_ARGON2_KEY_VERSION        @"V" /*uint32*/
#define KDF_ARGON2_KEY_SECRET_KEY     @"K"
#define KDF_ARGON2_KEY_ASSOC_DATA     @"A"

#define COMPRESSION_NONE       0
#define COMPRESSION_GZIP       1
#define COMPRESSION_COUNT      2

#define CSR_NONE               0
#define CSR_ARC4VARIANT        1
#define CSR_SALSA20            2
#define CSR_CHACHA20           3
#define CSR_COUNT              4

#define FIELD_TITLE            @"Title"
#define FIELD_USER_NAME        @"UserName"
#define FIELD_PASSWORD         @"Password"
#define FIELD_URL              @"URL"
#define FIELD_NOTES            @"Notes"

@interface Kdb4Group : KdbGroup

@property(nonatomic, strong) KdbUUID *uuid;
@property(nonatomic, copy) NSString *notes;
@property(nonatomic, strong) KdbUUID *customIconUuid;
@property(nonatomic, assign) BOOL isExpanded;
@property(nonatomic, copy) NSString *defaultAutoTypeSequence;
@property(nonatomic, copy) NSString *enableAutoType;
@property(nonatomic, copy) NSString *enableSearching;
@property(nonatomic, strong) KdbUUID *lastTopVisibleEntry;
@property(nonatomic, assign) BOOL expires;
@property(nonatomic, assign) NSInteger usageCount;
@property(nonatomic, strong) NSDate *locationChanged;

    // Array of CustomItem objects
@property(nonatomic, strong) NSMutableArray *customData;

- (Kdb4Group*)findGroup:(KdbUUID *)uuid;

@end


@interface StringField : NSObject <NSCopying>

@property(nonatomic, copy) NSString *key;
@property(nonatomic, copy) NSString *value;
@property(nonatomic, assign) BOOL protected;

- (id)initWithKey:(NSString *)key andValue:(NSString *)value;
- (id)initWithKey:(NSString *)key andValue:(NSString *)value andProtected:(BOOL)protected;

+ (id)stringFieldWithKey:(NSString *)key andValue:(NSString *)value;

@end


@interface CustomIcon : NSObject

@property(nonatomic, strong) KdbUUID *uuid;
@property(nonatomic, copy) NSString *data;

@end


@interface CustomItem : NSObject

@property(nonatomic, copy) NSString *key;
@property(nonatomic, copy) NSString *value;

@end


@interface Binary : NSObject

@property(nonatomic, assign) NSInteger binaryId;
@property(nonatomic, assign) BOOL compressed;
@property(nonatomic, strong) NSString *data;

@end


@interface BinaryRef : NSObject

@property(nonatomic, strong) NSString *key;
@property(nonatomic, assign) NSInteger index;
@property(nonatomic, strong) NSString *data;

@end


@interface Association : NSObject

@property(nonatomic, copy) NSString *window;
@property(nonatomic, copy) NSString *keystrokeSequence;

@end


@interface AutoType : NSObject

@property(nonatomic, assign) BOOL enabled;
@property(nonatomic, assign) NSInteger dataTransferObfuscation;
@property(nonatomic, copy) NSString *defaultSequence;
@property(nonatomic, readonly) NSMutableArray *associations;

@end


@interface DeletedObject : NSObject

@property(nonatomic, strong) KdbUUID *uuid;
@property(nonatomic, strong) NSDate *deletionTime;

@end


@interface Kdb4Entry : KdbEntry

@property(nonatomic, strong) KdbUUID *uuid;
@property(nonatomic, strong) StringField *titleStringField;
@property(nonatomic, strong) StringField *usernameStringField;
@property(nonatomic, strong) StringField *passwordStringField;
@property(nonatomic, strong) StringField *urlStringField;
@property(nonatomic, strong) StringField *notesStringField;
@property(nonatomic, strong) KdbUUID *customIconUuid;
@property(nonatomic, copy) NSString *foregroundColor;
@property(nonatomic, copy) NSString *backgroundColor;
@property(nonatomic, copy) NSString *overrideUrl;
@property(nonatomic, copy) NSString *tags;
@property(nonatomic, assign) BOOL expires;
@property(nonatomic, assign) NSInteger usageCount;
@property(nonatomic, strong) NSDate *locationChanged;
@property(nonatomic, readonly) NSMutableArray *stringFields;
@property(nonatomic, readonly) NSMutableDictionary *binaryDict;  // BinaryRefs
@property(nonatomic, strong) AutoType *autoType;
@property(nonatomic, readonly) NSMutableArray *history;

// Array of CustomItem objects
//@property(nonatomic, strong) NSMutableArray *customData;
@property NSMutableArray *customData;

- (BOOL)hasChanged:(Kdb4Entry*)entry;
- (Kdb4Entry*)deepCopy;

@end


@interface Kdb4Tree : KdbTree

@property(nonatomic, assign) uint32_t compressionAlgorithm;

@property(nonatomic, copy) NSString *generator;
@property(nonatomic, strong) NSData *headerHash;
@property(nonatomic, copy) NSString *databaseName;
@property(nonatomic, strong) NSDate *databaseNameChanged;
@property(nonatomic, copy) NSString *databaseDescription;
@property(nonatomic, strong) NSDate *databaseDescriptionChanged;
@property(nonatomic, copy) NSString *defaultUserName;
@property(nonatomic, strong) NSDate *defaultUserNameChanged;
@property(nonatomic, assign) NSInteger maintenanceHistoryDays;
@property(nonatomic, copy) NSString *color;
@property(nonatomic, strong) NSDate *masterKeyChanged;
@property(nonatomic, assign) NSInteger masterKeyChangeRec;
@property(nonatomic, assign) NSInteger masterKeyChangeForce;
@property(nonatomic, assign) BOOL protectTitle;
@property(nonatomic, assign) BOOL protectUserName;
@property(nonatomic, assign) BOOL protectPassword;
@property(nonatomic, assign) BOOL protectUrl;
@property(nonatomic, assign) BOOL protectNotes;
@property(nonatomic, readonly) NSMutableArray *customIcons;
@property(nonatomic, assign) BOOL recycleBinEnabled;
@property(nonatomic, strong) KdbUUID *recycleBinUuid;
@property(nonatomic, strong) NSDate *recycleBinChanged;
@property(nonatomic, strong) KdbUUID *entryTemplatesGroup;
@property(nonatomic, strong) NSDate *entryTemplatesGroupChanged;
@property(nonatomic, assign) NSInteger historyMaxItems;
@property(nonatomic, assign) NSInteger historyMaxSize;
@property(nonatomic, strong) KdbUUID *lastSelectedGroup;
@property(nonatomic, strong) KdbUUID *lastTopVisibleGroup;
@property(nonatomic, readonly) NSMutableArray *binaries;
@property(nonatomic, readonly) NSMutableArray *customData;
@property(nonatomic, strong) NSMutableArray *deletedObjects;

/* KDBX 4 Stuff */
@property uint32_t dbVersion;
@property uint32_t forcedVersion;
@property VariantDictionary *kdfParams;
@property VariantDictionary *customPluginData;
@property NSMutableArray *headerBinaries;
@property KdbUUID *encryptionAlgorithm;

@end
