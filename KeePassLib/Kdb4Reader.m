//
//  Kdb4.m
//  KeePass2
//
//  Created by Qiang Yu on 1/3/10.
//  Copyright 2010 Qiang Yu. All rights reserved.
//

#import <CommonCrypto/CommonCryptor.h>
#import "Kdb4Reader.h"
#import "Kdb.h"
#import "HashedInputData.h"
#import "GZipInputData.h"
#import "Kdb4Parser.h"
#import "Utils.h"
#import "AESDecryptSource.h"
#import "Arc4RandomStream.h"
#import "Salsa20RandomStream.h"

#define VERSION_CRITICAL_MAX_32 0x00030000
#define VERSION_CRITICAL_MASK 0xFFFF0000

#define READ_BYTES(X, Y, Z) (X = [[ByteBuffer alloc] initWithSize:Y dataSource:Z])

@interface Kdb4Reader (PrivateMethods)
-(void)readHeader:(id<InputDataSource>) source;
-(id<InputDataSource>)createDecryptedInputDataSource:(id<InputDataSource>)source key:(ByteBuffer *)key;
@end


@implementation Kdb4Reader

#pragma mark -
#pragma mark alloc/dealloc

-(id)init{
    self = [super init];
    if(self) {
        _password = [[KdbPassword alloc]init];
    }
    return self;
}

-(void)dealloc{
    [_cipherUUID release];
    [_encryptionIV release];
    [_protectedStreamKey release];
    [_streamStartBytes release];
    [_password release];
    [_tree release];
    [super dealloc];
}

#pragma mark -
#pragma mark Public Methods

//TODO:
// only Kdb4Format.Default is supported; will add support for Kdb4Format.PlainXml
//
- (KdbTree*)load:(WrapperNSData *)source withPassword:(NSString *)password {
    Kdb4Tree *tree = nil;
    ByteBuffer * finalKey = nil;
    
    @try {
        //read header
        [self readHeader:source];
        
        //decrypt data
        finalKey = [_password createFinalKey32ForPasssword:password encoding:NSUTF8StringEncoding kdbVersion:4];
        id<InputDataSource> decrypted = [self createDecryptedInputDataSource:source key:finalKey];
        
        //double check start block
        ByteBuffer * startBytes = [[ByteBuffer alloc] initWithSize:32];
        [decrypted readBytes:startBytes._bytes length:32];
        if(![startBytes isEqual:_streamStartBytes]) {
            [startBytes release];
            @throw [NSException exceptionWithName:@"DecryptError" reason:@"Failed to decrypt" userInfo:nil];
        }
        [startBytes release];
        
        id<InputDataSource> readerStream = [[[HashedInputData alloc] initWithDataSource:decrypted] autorelease];
        if(_compressionAlgorithm==COMPRESSION_GZIP){
            readerStream = [[[GZipInputData alloc] initWithDataSource:readerStream] autorelease];
        }
        
        //should PlainXML supported?
        id<RandomStream> rs = nil;
        if(_randomStreamID == CSR_SALSA20){
            rs = [[[Salsa20RandomStream alloc] init:_protectedStreamKey._bytes len:_protectedStreamKey._size] autorelease];
        }else if (_randomStreamID == CSR_ARC4VARIANT){
            rs = [[[Arc4RandomStream alloc] init:_protectedStreamKey._bytes len:_protectedStreamKey._size] autorelease];
        }else{
            @throw [NSException exceptionWithName:@"Unsupported" reason:@"UnsupportedRandomStreamID" userInfo:nil];
        }
        
        Kdb4Parser * parser = [[Kdb4Parser alloc] init];
        parser._randomStream = rs;
        
        tree = [parser parse:readerStream];
        
        [parser release];
    }
    @finally{
        [finalKey release];
    }
    
    return tree;
}

#pragma mark -
#pragma mark Private Methods

/*
 * Decrypt remaining bytes
 */
-(id<InputDataSource>)createDecryptedInputDataSource:(id<InputDataSource>)source key:(ByteBuffer *)key{
    return [[[AESDecryptSource alloc] initWithInputSource:source Keys:key._bytes andIV:_encryptionIV._bytes] autorelease];
}

-(void)readHeader:(id<InputDataSource>)source{
    uint32_t version = [Utils readInt32LE:source];
        
    if((version & VERSION_CRITICAL_MASK) > (VERSION_CRITICAL_MAX_32 & VERSION_CRITICAL_MASK)){
        @throw [NSException exceptionWithName:@"Unsupported" reason:@"Unsupported version" userInfo:nil];
    }
    
    BOOL eoh = NO; //end of header
    
    while(!eoh){
        uint8_t fieldType = [Utils readInt8LE:source];
        uint16_t fieldSize = [Utils readInt16LE:source];
        switch (fieldType) {
            case HEADER_COMMENT:{
                ByteBuffer * comment;
                READ_BYTES(comment, fieldSize, source);
                [comment release];
                break;
            }
            case HEADER_EOH:{
                ByteBuffer * header;
                READ_BYTES(header, fieldSize, source);
                [header release];
                eoh = YES;
                break;
            }
            case HEADER_CIPHERID:{
                if(fieldSize!=16)
                    @throw [NSException exceptionWithName:@"InvalidHeader" reason:@"InvalidCipherId" userInfo:nil];
                _cipherUUID = [[UUID alloc]initWithSize:16 dataSource:source];
                if(![_cipherUUID isEqual:[UUID getAESUUID]]){
                    @throw [NSException exceptionWithName:@"Unsupported" reason:@"UnsupportedCipher" userInfo:nil];
                }
                break;
            }
            case HEADER_MASTERSEED:{
                if(fieldSize!=32)
                    @throw [NSException exceptionWithName:@"InvalidHeader" reason:@"InvalidMasterSeed" userInfo:nil];
                ByteBuffer * masterSeed;
                READ_BYTES(masterSeed, fieldSize, source);
                _password._masterSeed = masterSeed;
                [masterSeed release];
                break;
            }
            case HEADER_TRANSFORMSEED:{
                if(fieldSize!=32)
                    @throw [NSException exceptionWithName:@"InvalidHeader" reason:@"InvalidTransformSeed" userInfo:nil];
                ByteBuffer * transformSeed;
                READ_BYTES(transformSeed, fieldSize, source);
                _password._transformSeed = transformSeed;
                [transformSeed release];
                break;
            }
            case HEADER_ENCRYPTIONIV:{
                READ_BYTES(_encryptionIV, fieldSize, source);
                break;
            }
            case HEADER_PROTECTEDKEY:{
                READ_BYTES(_protectedStreamKey, fieldSize, source);
                break;
            }
            case HEADER_STARTBYTES:{
                READ_BYTES(_streamStartBytes, fieldSize, source);
                break;
            }
            case HEADER_TRANSFORMROUNDS:{
                _password._rounds = [Utils readInt64LE:source];
                break;
            }
            case HEADER_COMPRESSION:{
                _compressionAlgorithm = [Utils readInt32LE:source];
                if(_compressionAlgorithm >= COMPRESSION_COUNT)
                    @throw [NSException exceptionWithName:@"InvalidHeader" reason:@"InvalidCompression" userInfo:nil];
                break;
            }
            case HEADER_RANDOMSTREAMID:{
                _randomStreamID = [Utils readInt32LE:source];
                if(_randomStreamID >= CSR_COUNT)
                    @throw [NSException exceptionWithName:@"InvalidHeader" reason:@"InvalidCSRAlgorithm" userInfo:nil];
                break;
            }
            default:
                @throw [NSException exceptionWithName:@"InvalidHeader" reason:@"InvalidField" userInfo:nil];
        }
    }
}

@end
