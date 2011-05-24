//
//  Kdb3Persist.m
//  KeePass2
//
//  Created by Qiang Yu on 2/16/10.
//  Copyright 2010 Qiang Yu. All rights reserved.
//

#import "Kdb3Writer.h"
#import "Kdb3Node.h"
#import "Kdb3Persist.h"
#import "DataOutputStream.h"
#import "AesOutputStream.h"
#import "Sha256OutputStream.h"
#import "Utils.h"

#define DEFAULT_BIN_SIZE (32*1024)

@interface Kdb3Writer (PrivateMethods)
- (uint32_t)numOfGroups:(Kdb3Group*)root;
- (uint32_t)numOfEntries:(Kdb3Group*)root;
- (void)writeHeader:(OutputStream*)outputStream withRoot:(Kdb3Group*)root;
@end

@implementation Kdb3Writer

- init {
    self = [super init];
    if (self) {
        masterSeed = [Utils randomBytes:16];
        encryptionIv = [Utils randomBytes:16];
        transformSeed = [Utils randomBytes:32];
        rounds = 6000;
    }
    return self;
}

/**
 * Get the number of groups in the KDB tree
 */
- (uint32_t)numOfGroups:(Kdb3Group*)root {
    int num = 0;
    for (Kdb3Group *g in root.groups) {
        num += [self numOfGroups:g];
    }
    return num+1;
}

/**
 * Get the number of entries and meta entries in the KDB tree
 */
- (uint32_t)numOfEntries:(Kdb3Group*)root {
    int num = [root.entries count] + [root.metaEntries count];
    for (Kdb3Group *g in root.groups) {
        num += [self numOfEntries:g];
    }
    return num;
}

/**
 * Write the KDB3 header
 */
- (void)writeHeader:(OutputStream*)outputStream withRoot:(Kdb3Group*)root {
    // Signature, Flags & Version
    [outputStream writeInt32:CFSwapInt32HostToLittle(KDB3_SIG1)];
    [outputStream writeInt32:CFSwapInt32HostToLittle(KDB3_SIG2)];
    [outputStream writeInt32:CFSwapInt32HostToLittle(FLAG_SHA2|FLAG_RIJNDAEL)];
    [outputStream writeInt32:CFSwapInt32HostToLittle(KDB3_VER)];
    
    [outputStream write:masterSeed];
    [outputStream write:encryptionIv];
    
    uint32_t numGroups = [self numOfGroups:root] - 1; // Minus the root
    [outputStream writeInt32:CFSwapInt32HostToLittle(numGroups)];
    
    uint32_t numEntries = [self numOfEntries:root];
    [outputStream writeInt32:CFSwapInt32HostToLittle(numEntries)];
    
    // Write a bogus content hash until we can go back and fill it in
    uint8_t contentHash[32];
    memset(contentHash, 0xFF, 32);
    [outputStream write:contentHash length:32];
    
    [outputStream write:transformSeed];
    
    [outputStream writeInt32:CFSwapInt32HostToLittle(rounds)];
}

/**
 * Persist a tree into a file, using the specified password
 */
- (void)persist:(Kdb3Tree*)tree file:(NSString*)filename withPassword:(NSString*)password {
    DataOutputStream *dataOutputStream = [[DataOutputStream alloc] init];
    
    // Write the header
    [self writeHeader:dataOutputStream withRoot:(Kdb3Group*)tree.root];
    
    // Create the encryption output stream
    NSData *key = [KdbPassword createFinalKey32ForPasssword:password encoding:NSWindowsCP1252StringEncoding kdbVersion:3 masterSeed:masterSeed transformSeed:transformSeed rounds:rounds];
    AesOutputStream *aesOutputStream = [[AesOutputStream alloc] initWithOutputStream:dataOutputStream key:key iv:encryptionIv];
    
    // Wrap the AES output stream in a SHA256 output stream to calculate a hash
    Sha256OutputStream *outputStream = [[Sha256OutputStream alloc] initWithOutputStream:aesOutputStream];
    
    Kdb3Persist *persist = nil;
    @try {
        // Persist the database
        persist = [[Kdb3Persist alloc] initWithTree:tree andOutputStream:outputStream];
        [persist persist];
        
        [outputStream close];
        
        NSMutableData *data = dataOutputStream.data;
        
        // Back fill the content hash
        NSRange range;
        range.location = 56;
        range.length = 32;
        [data replaceBytesInRange:range withBytes:[outputStream getHash]];
        
        // Save the data to file
        if (![data writeToFile:filename atomically:YES]) {
            @throw [NSException exceptionWithName:@"IOException" reason:@"Failed to write to file" userInfo:nil];
        }
    } @finally {
        [persist release];
        [outputStream release];
        [aesOutputStream release];
        [dataOutputStream release];
    }
}

- (void)newFile:(NSString*)fileName withPassword:(NSString*)password {
    Kdb3Tree *tree = [[Kdb3Tree alloc] initNewTree];
    [self persist:tree file:fileName withPassword:password];
    [tree release];
    
}

@end
