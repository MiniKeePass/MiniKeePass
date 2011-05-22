//
//  Kdb3Persist.m
//  KeePass2
//
//  Created by Qiang Yu on 2/16/10.
//  Copyright 2010 Qiang Yu. All rights reserved.
//

#import "Kdb3Writer.h"
#import "Kdb3Node.h"
#import "Utils.h"
#import "AESEncryptSource.h"
#import "Kdb3Persist.h"

#define DEFAULT_BIN_SIZE (32*1024)

@interface Kdb3Writer (PrivateMethods)
- (uint32_t)numOfGroups:(Kdb3Group*)root;
- (uint32_t)numOfEntries:(Kdb3Group*)root;
- (void)writeHeader:(Kdb3Group*)root kdbPassword:(KdbPassword*)kdbPassword iv:(uint8_t*)iv buffer:(NSMutableData*)buffer;
@end


@implementation Kdb3Writer

/**
 * Get the number of groups in the KDB tree, including the %ROOT% node 
 * although it will not be persisted
 */
-(uint32_t)numOfGroups:(Kdb3Group *) root {
    int num = 0;
    for(Kdb3Group * g in root.groups){
        num+=[self numOfGroups:g];
    }
    return num+1;
}

/**
 * Get the total number of entries and meta entries in the KDB tree
 *
 */
-(uint32_t)numOfEntries:(Kdb3Group *)root{
    int num = [root.entries count] + [root.metaEntries count];
    for(Kdb3Group * g in root.groups){
        num+=[self numOfEntries:g];
    }
    return num;
}

/**
 * Write the KDB3 header
 *
 */
- (void)writeHeader:(Kdb3Group *)root kdbPassword:(KdbPassword*)kdbPassword iv:(uint8_t*)iv buffer:(NSMutableData *)buffer {
    uint8_t header[KDB3_HEADER_SIZE];

    //Version, Flags & Version
    *((uint32_t *)(header)) = SWAP_INT32_HOST_TO_LE(KDB3_SIG1);   //0..3
    *((uint32_t *)(header+4)) = SWAP_INT32_HOST_TO_LE(KDB3_SIG2); //4..7
    *((uint32_t *)(header+8)) = SWAP_INT32_HOST_TO_LE(FLAG_SHA2|FLAG_RIJNDAEL); //8..11
    *((uint32_t *)(header+12)) = SWAP_INT32_HOST_TO_LE(KDB3_VER); //12..15
    
    memcpy(header+16, kdbPassword._masterSeed._bytes, 16); //16..31
    memcpy(header+32, iv, 16);  //32..47
    
    uint32_t numGroups = [self numOfGroups:root]-1; //minus the root itself
    uint32_t numEntries = [self numOfEntries:root];
    
    *((uint32_t *)(header+48)) = SWAP_INT32_HOST_TO_LE(numGroups); //48..51
    *((uint32_t *)(header+52)) = SWAP_INT32_HOST_TO_LE(numEntries); //52..55
    
    //56..87 content hash
    
    memcpy(header+88, kdbPassword._transformSeed._bytes, 32); //88..119
    *((uint32_t *)(header+120)) = SWAP_INT32_HOST_TO_LE(kdbPassword._rounds); //120..123
    [buffer appendBytes:header length:KDB3_HEADER_SIZE]; 
}

/**
 * Persist a tree into a file, using the specified password
 */
- (void)persist:(Kdb3Tree*)tree file:(NSString*)filename withPassword:(NSString*)password {
    KdbPassword *kdbPassword = [[KdbPassword alloc] initForEncryption:16];
    
    // Setup the encryption initialization vector
    uint8_t encryptionIv[16];
    *((uint32_t *)&encryptionIv[0]) = arc4random();
    *((uint32_t *)&encryptionIv[4]) = arc4random();
    *((uint32_t *)&encryptionIv[8]) = arc4random();
    *((uint32_t *)&encryptionIv[12]) = arc4random();
    
    ByteBuffer *finalKey = [kdbPassword createFinalKey32ForPasssword:password encoding:NSWindowsCP1252StringEncoding kdbVersion:3];
    
    // write the header
    NSMutableData * data = [[NSMutableData alloc]initWithCapacity:DEFAULT_BIN_SIZE];
    [self writeHeader:(Kdb3Group *)tree.root kdbPassword:kdbPassword iv:encryptionIv buffer:data];
    
    AESEncryptSource * enc = [[AESEncryptSource alloc] init:finalKey._bytes andIV:encryptionIv];
    enc._data = data;
    [data release];
    [finalKey release];
    [kdbPassword release];

    Kdb3Persist * persist = nil;
    
    @try{
        persist = [[Kdb3Persist alloc]initWithTree:tree andDest:enc];
        [persist persist];
        NSRange range;
        range.location = 56;
        range.length = 32;
        //backfill the content hash
        [enc._data replaceBytesInRange:range withBytes:[enc getHash]];
        if(![enc._data writeToFile:filename atomically:YES]){
            @throw [NSException exceptionWithName:@"IOError" reason:@"WriteFile" userInfo:nil];
        }
    }@finally {
        [persist release];
        [enc release];
    }
}

-(void)newFile:(NSString *)fileName withPassword:(NSString *)password{
    Kdb3Tree *tree = [[Kdb3Tree alloc] initNewTree];
    [self persist:tree file:fileName withPassword:password];
    [tree release];
    
}

@end
