//
//   Kdb3.m
//   KeePass
//
//   Created by Qiang Yu on 11/22/09.
//   Copyright 2009 Qiang Yu. All rights reserved.
//

#import "Kdb3Reader.h"
#import "Kdb3Parser.h"
#import "AesInputStream.h"
#import "KdbPassword.h"

@interface Kdb3Reader (privateMethods)
- (void)readHeader:(InputStream*)inputStream;
@end

@implementation Kdb3Reader

- (id)init {
    self = [super init];
    if (self) {
        masterSeed = nil;
        encryptionIv = nil;
        numGroups = 0;
        numEntries = 0;
        contentHash = nil;
        transformSeed = nil;
        rounds = 0;
    }
    return self;
}

- (void)dealloc {
    [masterSeed release];
    [encryptionIv release];
    [contentHash release];
    [transformSeed release];
    [super dealloc];
}

- (void)readHeader:(InputStream*)inputStream {
    uint8_t buffer[32];
    
    flags = [inputStream readInt32];
    flags = CFSwapInt32LittleToHost(flags);
    
    version = [inputStream readInt32];
    version = CFSwapInt32LittleToHost(version);
    
    // Check the version
    if ((version & 0xFFFFFF00) != (KDB3_VER & 0xFFFFFF00)) {
        @throw [NSException exceptionWithName:@"Unsupported" reason:@"Unsupported version" userInfo:nil];
    }
    
    // Check the encryption algorithm
    if (!(flags & FLAG_RIJNDAEL)) {
        @throw [NSException exceptionWithName:@"Unsupported" reason:@"Unsupported algorithm" userInfo:nil];
    }
    
    [inputStream read:buffer length:16];
    masterSeed = [[NSData alloc] initWithBytes:buffer length:16];

    [inputStream read:buffer length:16];
    encryptionIv = [[NSData alloc] initWithBytes:buffer length:16];
    
    numGroups = [inputStream readInt32];
    numGroups = CFSwapInt32LittleToHost(numGroups);
    
    numEntries = [inputStream readInt32];
    numEntries = CFSwapInt32LittleToHost(numEntries);
    
    [inputStream read:buffer length:32];
    contentHash = [[NSData alloc] initWithBytes:buffer length:32];
    
    [inputStream read:buffer length:32];
    transformSeed = [[NSData alloc] initWithBytes:buffer length:32];
    
    rounds = [inputStream readInt32];
    rounds = CFSwapInt32LittleToHost(rounds);
}

- (KdbTree*)load:(InputStream*)inputStream withPassword:(KdbPassword*)kdbPassword {
    Kdb3Tree *tree;
    
    // Read the header
    [self readHeader:inputStream];
    
    NSData *key = [kdbPassword createFinalKeyForVersion:3 masterSeed:masterSeed transformSeed:transformSeed rounds:rounds];
    AesInputStream *aesInputStream = [[AesInputStream alloc] initWithInputStream:inputStream key:key iv:encryptionIv];

    Kdb3Parser *parser = [[Kdb3Parser alloc]init];
    @try {
        tree = [parser parse:aesInputStream numGroups:numGroups numEntris:numEntries];
    } @finally {
        [parser release];
        [aesInputStream release];
    }
    
    return tree;
}

@end
