//
//  KDB3Node.h
//  KeePass2
//
//  Created by Qiang Yu on 2/12/10.
//  Copyright 2010 Qiang Yu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Kdb.h"
#import "UUID.h"

#define KDB3_SIG1 (0x9AA2D903)
#define KDB3_SIG2 (0xB54BFB65)

#define KDB3_VER  (0x00030004)
#define KDB3_HEADER_SIZE (124)

#define FLAG_SHA2     1
#define FLAG_RIJNDAEL 2
#define FLAG_ARCFOUR  4
#define FLAG_TWOFISH  8

typedef struct {
	uint32_t signature1;
	uint32_t signature2;
	uint32_t flags;
	uint32_t version;

	uint8_t masterSeed[16];
	uint8_t encryptionIv[16];

	uint32_t groups;
	uint32_t entries;

	uint8_t contentsHash[32];

	uint8_t masterSeed2[32];
	uint32_t keyEncRounds;
} kdb3_header_t;

@interface Kdb3Group : KdbGroup

@property(nonatomic, assign) uint32_t groupId;
@property(nonatomic, assign) uint32_t flags;
@property(nonatomic, readonly) NSMutableArray *metaEntries;

@end


@interface Kdb3Entry : KdbEntry

@property(nonatomic, strong) KdbUUID *uuid;
@property(nonatomic, copy) NSString *title;
@property(nonatomic, copy) NSString *username;
@property(nonatomic, copy) NSString *password;
@property(nonatomic, copy) NSString *url;
@property(nonatomic, copy) NSString *notes;
@property(nonatomic, copy) NSString *binaryDesc;
@property(nonatomic, strong) NSData *binary;

- (BOOL)isMeta;
- (BOOL)hasChanged:(Kdb3Entry*)entry;
- (KdbEntry*)deepCopy;

@end


@interface Kdb3Tree : KdbTree

@property(nonatomic, assign) uint32_t flags;
@property(nonatomic, assign) uint32_t rounds;

- (id)init;

@end
