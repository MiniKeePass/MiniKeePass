//
//  Kdb4.m
//  KeePass2
//
//  Created by Qiang Yu on 1/3/10.
//  Copyright 2010 Qiang Yu. All rights reserved.
//

#import <CommonCrypto/CommonCryptor.h>
#import "Kdb4Reader.h"
#import "Kdb4Parser.h"
#import "AesInputStream.h"
#import "HashedInputStream.h"
#import "GZipInputStream.h"
#import "Arc4RandomStream.h"
#import "Salsa20RandomStream.h"
#import "KdbPassword.h"
#import "UUID.h"

#define VERSION_CRITICAL_MAX_32 0x00030000
#define VERSION_CRITICAL_MASK 0xFFFF0000

@interface Kdb4Reader (PrivateMethods)
- (void)readHeader:(InputStream*)inputStream;
@end

@implementation Kdb4Reader

- (void)dealloc {
    [encryptionIv release];
    [masterSeed release];
    [transformSeed release];
    [streamStartBytes release];
    
    [cipherUuid release];
    [protectedStreamKey release];

    [_tree release];
    [super dealloc];
}

- (KdbTree*)load:(InputStream*)inputStream withPassword:(NSString*)password {
    Kdb4Tree *tree = nil;
    
    //read header
    [self readHeader:inputStream];
    
    if (![cipherUuid isEqual:[UUID getAESUUID]]) {
        @throw [NSException exceptionWithName:@"Unsupported" reason:@"UnsupportedCipher" userInfo:nil];
    }
    
    //decrypt data
    NSData *key = [KdbPassword createFinalKey32ForPasssword:password encoding:NSUTF8StringEncoding kdbVersion:4 masterSeed:masterSeed transformSeed:transformSeed rounds:rounds];
    AesInputStream *aesInputStream = [[AesInputStream alloc] initWithInputStream:inputStream key:key iv:encryptionIv];
    
    // Verify the stream start bytes match
    NSData *startBytes = [aesInputStream readData:32];
    if (![startBytes isEqual:streamStartBytes]) {
        @throw [NSException exceptionWithName:@"DecryptError" reason:@"Failed to decrypt" userInfo:nil];
    }
    
    InputStream *stream = [[[HashedInputStream alloc] initWithInputStream:aesInputStream] autorelease];
    if (compressionAlgorithm == COMPRESSION_GZIP) {
        stream = [[[GZipInputStream alloc] initWithInputStream:stream] autorelease];
    }
    
    //should PlainXML supported?
    id<RandomStream> rs = nil;
    if (randomStreamID == CSR_SALSA20) {
        rs = [[[Salsa20RandomStream alloc] init:protectedStreamKey] autorelease];
    } else if (randomStreamID == CSR_ARC4VARIANT) {
        rs = [[[Arc4RandomStream alloc] init:protectedStreamKey] autorelease];
    } else {
        @throw [NSException exceptionWithName:@"Unsupported" reason:@"UnsupportedRandomStreamID" userInfo:nil];
    }
    
    Kdb4Parser * parser = [[Kdb4Parser alloc] init];
    parser._randomStream = rs;
    
    tree = [parser parse:stream];
    
    [parser release];
    [aesInputStream release];
    
    return tree;
}

- (void)readHeader:inputStream {
    uint32_t version = [inputStream readInt32];
    version = CFSwapInt32LittleToHost(version);
        
    if ((version & VERSION_CRITICAL_MASK) > (VERSION_CRITICAL_MAX_32 & VERSION_CRITICAL_MASK)) {
        @throw [NSException exceptionWithName:@"Unsupported" reason:@"Unsupported version" userInfo:nil];
    }
    
    BOOL eoh = NO;
    while (!eoh) {
        uint8_t fieldType = [inputStream readInt8];

        uint16_t fieldSize = [inputStream readInt16];
        fieldSize = CFSwapInt16LittleToHost(fieldSize);
        
        switch (fieldType) {
            case HEADER_EOH:{
                NSData *skip = [inputStream readData:fieldSize];
                eoh = YES;
                break;
            }
            case HEADER_COMMENT:{
                // FIXME this should prolly be a string
                comment = [[inputStream readData:fieldSize] retain];
                break;
            }
            case HEADER_CIPHERID:{
                if (fieldSize != 16) {
                    @throw [NSException exceptionWithName:@"IOException" reason:@"Invalid cipher id" userInfo:nil];
                }
                cipherUuid = [[inputStream readData:fieldSize] retain];
                break;
            }
            case HEADER_MASTERSEED:{
                if (fieldSize != 32) {
                    @throw [NSException exceptionWithName:@"IOException" reason:@"Invalid field size" userInfo:nil];
                }
                masterSeed = [[inputStream readData:fieldSize] retain];
                break;
            }
            case HEADER_TRANSFORMSEED:{
                if (fieldSize != 32) {
                    @throw [NSException exceptionWithName:@"IOException" reason:@"Invalid field size" userInfo:nil];
                }
                
                transformSeed = [[inputStream readData:fieldSize] retain];
                break;
            }
            case HEADER_ENCRYPTIONIV:{
                encryptionIv = [[inputStream readData:fieldSize] retain];
                break;
            }
            case HEADER_PROTECTEDKEY:{
                protectedStreamKey = [[inputStream readData:fieldSize] retain];
                break;
            }
            case HEADER_STARTBYTES:{
                streamStartBytes = [[inputStream readData:fieldSize] retain];
                break;
            }
            case HEADER_TRANSFORMROUNDS:{
                rounds = [inputStream readInt64];
                rounds = CFSwapInt64LittleToHost(rounds);
                break;
            }
            case HEADER_COMPRESSION:{
                compressionAlgorithm = [inputStream readInt32];
                compressionAlgorithm = CFSwapInt32LittleToHost(compressionAlgorithm);
                if (compressionAlgorithm >= COMPRESSION_COUNT) {
                    @throw [NSException exceptionWithName:@"IOException" reason:@"Invalid compression" userInfo:nil];
                }
                break;
            }
            case HEADER_RANDOMSTREAMID:{
                randomStreamID = [inputStream readInt32];
                randomStreamID = CFSwapInt32LittleToHost(randomStreamID);
                if (randomStreamID >= CSR_COUNT) {
                    @throw [NSException exceptionWithName:@"IOException" reason:@"Invalid CSR algorithm" userInfo:nil];
                }
                break;
            }
            default:
                @throw [NSException exceptionWithName:@"InvalidHeader" reason:@"InvalidField" userInfo:nil];
        }
    }
}

@end
