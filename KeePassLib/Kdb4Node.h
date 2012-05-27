//
//  Kdb4Node.h
//  KeePass2
//
//  Created by Qiang Yu on 2/23/10.
//  Copyright 2010 Qiang Yu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Kdb.h"
#import "DDXML.h"
#import "DDXMLElementAdditions.h"

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

@interface Kdb4Group : KdbGroup {
    DDXMLElement *element;
}

@property(nonatomic, retain) DDXMLElement *element;

- (id)initWithElement:(DDXMLElement*)e;

@end


@class StringField;

@interface Kdb4Entry : KdbEntry {
    DDXMLElement *element;
    NSMutableArray *stringFields;
}

@property(nonatomic, retain) DDXMLElement *element;
@property(nonatomic, retain) NSArray *stringFields;

- (id)initWithElement:(DDXMLElement*)e;

- (void)addStringField:(StringField*)stringField;
- (void)removeStringField:(StringField*)stringField;

@end


@interface StringField : NSObject {
    Kdb4Entry *parent;
    NSString *name;
    NSString *value;
    DDXMLElement *element;
}

@property(nonatomic, retain) Kdb4Entry *parent;
@property(nonatomic, copy) NSString *name;
@property(nonatomic, copy) NSString *value;
@property(nonatomic, retain) DDXMLElement *element;

- (id)initWithElement:(DDXMLElement*)element;

@end


@interface Kdb4Tree : KdbTree {
    DDXMLDocument *document;
    uint64_t rounds;
    uint32_t compressionAlgorithm;
}

@property(nonatomic, retain) DDXMLDocument *document;
@property(nonatomic, assign) uint64_t rounds;
@property(nonatomic, assign) uint32_t compressionAlgorithm;

- (id)initWithDocument:(DDXMLDocument*)doc;
- (StringField*)createStringField:(Kdb4Entry*)parent;

@end
