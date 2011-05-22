//
//  Password.m
//  KeePass2
//
//  Created by Qiang Yu on 1/5/10.
//  Copyright 2010 Qiang Yu. All rights reserved.
//

#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonCryptor.h>

#import "KdbPassword.h"
#import "Utils.h"

@interface KdbPassword(PrivateMethods)
-(void)transformKeyHash:(uint8_t *)keyHash result:(uint8_t *)result;
@end

@implementation KdbPassword

@synthesize _masterSeed;
@synthesize _transformSeed;
@synthesize _rounds;

- (id)initForEncryption:(NSInteger)masterSeedSize {
    self = [super init];
    if (self) {
        _masterSeed = [[ByteBuffer alloc]initWithSize:masterSeedSize];
        [Utils getRandomBytes:_masterSeed._bytes length:_masterSeed._size];
        
        _transformSeed = [[ByteBuffer alloc] initWithSize:32];
        [Utils getRandomBytes:_transformSeed._bytes length:_transformSeed._size];
        
        _rounds = 6000;
    }
    return self;
}
 
-(void)dealloc{
    [_masterSeed release];
    [_transformSeed release];
    [super dealloc];
}

-(void)transformKeyHash:(uint8_t *)keyHash result:(uint8_t *)result{
    size_t tmp;
    
    CCCryptorRef cryptorRef = nil;
    CCCryptorCreate(kCCEncrypt, kCCAlgorithmAES128,kCCOptionECBMode,_transformSeed._bytes,
                    kCCKeySizeAES256, nil,&cryptorRef);
    
    for(int i=0; i<_rounds; i++){
        CCCryptorUpdate(cryptorRef, keyHash, 32, keyHash, 32, &tmp);
    }
    
    // no need to call CCCryptorFinal
    CCCryptorRelease(cryptorRef);
    
    CC_SHA256(keyHash, 32, result);
}

- (ByteBuffer*)createFinalKey32ForPasssword:(NSString*)password encoding:(NSStringEncoding)encoding kdbVersion:(uint8_t)ver {
    ByteBuffer *pwd = [[ByteBuffer alloc] initWithString:password encoding:encoding];
    
    uint8_t keyHash[32];
    CC_SHA256(pwd._bytes, pwd._size, keyHash);
    
    ///////////////////////////////////////////////////
    //
    // !!! NOTE: KDB3 may not need the extra hash below
    //
    ///////////////////////////////////////////////////
    if(ver==4) CC_SHA256(keyHash, 32, keyHash);
    
    [pwd release];

    //step 1 transform the key
    uint8_t transformed[32];
    [self transformKeyHash:keyHash result:transformed];
    
    //step 2 hash the transform result
    ByteBuffer * rv = [[ByteBuffer alloc]initWithSize:32];
    CC_SHA256_CTX ctx;
    CC_SHA256_Init(&ctx);
    CC_SHA256_Update(&ctx, _masterSeed._bytes, _masterSeed._size);
    CC_SHA256_Update(&ctx, transformed, 32);
    CC_SHA256_Final(rv._bytes, &ctx);
    return rv;
}
@end
