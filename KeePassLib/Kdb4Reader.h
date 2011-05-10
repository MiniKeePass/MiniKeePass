//
//  Kdb4.h
//  KeePass2
//
//  Created by Qiang Yu on 1/3/10.
//  Copyright 2010 Qiang Yu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ByteBuffer.h"
#import "UUID.h"
#import "KdbPassword.h"
#import "Tree.h"
#import "Kdb4Node.h"
#import "KdbReader.h"
#import "WrapperNSData.h"

#define KDB4_VERSION (0x00010001)
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

#define CSR_NONE		0
#define CSR_ARC4VARIANT 1
#define CSR_SALSA20		2
#define CSR_COUNT		3

@interface Kdb4Reader : NSObject<KdbReader>{
	UUID * _cipherUUID;
	
	ByteBuffer * _encryptionIV, * _protectedStreamKey, * _streamStartBytes;
	uint32_t _compressionAlgorithm, _randomStreamID;

	KdbPassword * _password;	
	Kdb4Tree * _tree;
}

@property(nonatomic, retain) Kdb4Tree * _tree;

-(id<KdbTree>)load:(WrapperNSData *)source withPassword:(NSString *)password;
@end
