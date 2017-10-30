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

#import "Kdb4Writer.h"
#import "Kdb4Node.h"
#import "Kdb4Persist.h"
#import "KdbPassword.h"
#import "DataOutputStream.h"
#import "CipherStreamFactory.h"
#import "HashedOutputStream.h"
#import "HmacInputStream.h"
#import "HmacOutputStream.h"
#import "GZipOutputStream.h"
#import "Salsa20RandomStream.h"
#import "ChaCha20RandomStream.h"
#import "UUID.h"
#import "Utils.h"
#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonHMAC.h>

#define DEFAULT_BIN_SIZE (32*1024)

@interface Kdb4Writer (PrivateMethods)
- (void)writeHeaderField:(OutputStream*)outputStream headerId:(uint8_t)headerId data:(const void*)data length:(uint16_t)length;
- (void)writeHeader:(OutputStream*)outputStream withTree:(Kdb4Tree*)tree;
- (uint32_t)getMinDatabaseVersion:(Kdb4Tree*)tree;
@end

@implementation Kdb4Writer

- init {
    self = [super init];
    if (self) {
        masterSeed = [Utils randomBytes:32];
        protectedStreamKey = [Utils randomBytes:32];
        streamStartBytes = [Utils randomBytes:32];
    }
    return self;
}

- (void)persist:(Kdb4Tree*)tree file:(NSString*)filename withPassword:(KdbPassword*)kdbPassword {
    uint8_t hmackey64[64];
    uint8_t *mseed = (uint8_t *) masterSeed.bytes;
    uint8_t headerHmac[CC_SHA256_DIGEST_LENGTH];
    
    // Update the generator
    tree.generator = @"MiniKeePass";
    
    // Configure the output stream
    DataOutputStream *outputStream = [[DataOutputStream alloc] init];
    
    // Determine what version database to use
    dbVersion = [self getMinDatabaseVersion:tree];
    tree.dbVersion = dbVersion;
    
    // Get a new Random seed.
    KdbUUID *KDFUuid = [[KdbUUID alloc] initWithData:tree.kdfParams[KDF_KEY_UUID_BYTES]];
    if ([KDFUuid isEqual:[KdbUUID getAES_KDFUUID]]) {
        [tree.kdfParams addByteArray:[Utils randomBytes:32] forKey:KDF_AES_KEY_SEED];
    } else if ([KDFUuid isEqual:[KdbUUID getArgon2UUID]]) {
        [tree.kdfParams addByteArray:[Utils randomBytes:32] forKey:KDF_ARGON2_KEY_SALT];
    } else {
        @throw [NSException exceptionWithName:@"CipherError" reason:@"Unknown Cipher Uuid" userInfo:nil];
    }
    
        // Create the new encryptionIv
    if ([tree.encryptionAlgorithm isEqual:[KdbUUID getAESUUID]]) {
        encryptionIv = [Utils randomBytes:16];
    } else if ([tree.encryptionAlgorithm isEqual:[KdbUUID getChaCha20UUID]]) {
        encryptionIv = [Utils randomBytes:12];
    } else {
        @throw [NSException exceptionWithName:@"CipherError" reason:@"Unknown Cipher Uuid" userInfo:nil];
    }

    // Write the header
    [self writeHeader:outputStream withTree:tree];

    // Compute a hash of the header data
    NSData *headerBytes = [[NSData alloc] initWithData:outputStream.data];
    tree.headerHash = [self computeHashOfHeaderData:headerBytes];
    
    // Create the encryption output stream
    NSData *key = [kdbPassword createFinalKeyKDBX4:tree.kdfParams masterSeed:mseed HmacKey64:hmackey64 ];
    OutputStream *stream;
    RandomStream *randomStream;
    if (dbVersion < KDBX40_VERSION) {   // KDBX 3.1
        stream = [CipherStreamFactory getOutputStream:tree.encryptionAlgorithm stream:outputStream key:key iv:encryptionIv];
        
        // Write the stream start bytes
        [stream write:streamStartBytes];
        
        // Create the hashed output stream
        stream = [[HashedOutputStream alloc] initWithOutputStream:stream blockSize:1024*1024];
        
        // Create the random stream
        randomStream = [[Salsa20RandomStream alloc] init:protectedStreamKey];

    } else {   // KDBX 4
        // Write the SHA-256 hash of the header bytes
        [outputStream write:tree.headerHash];
        
        // Write the HMAC-SHA-256 of the header bytes
        NSData *hmacKey = [HmacInputStream getHMACKey:(void *)hmackey64 keylen:64 blockIndex:ULLONG_MAX];
        CCHmac(kCCHmacAlgSHA256, hmacKey.bytes, hmacKey.length, headerBytes.bytes, (size_t)headerBytes.length, headerHmac);
        [outputStream write:headerHmac length:CC_SHA256_DIGEST_LENGTH];
        
        // Create the HMAC Block output stream
        NSData *hmacKeyData = [[NSData alloc] initWithBytes:hmackey64 length:64];
        HmacOutputStream *hmacStream = [[HmacOutputStream alloc] initWithOutputStream:outputStream key:hmacKeyData];
        
        // Create the encrypted input stream
        stream = [CipherStreamFactory getOutputStream:tree.encryptionAlgorithm stream:hmacStream key:key iv:encryptionIv];
        
        // Create the random stream, need a longer seed.
        protectedStreamKey = [Utils randomBytes:64];
        randomStream = [[ChaCha20RandomStream alloc] init:protectedStreamKey];
    }
    
    // Create the gzip output stream
    if (tree.compressionAlgorithm == COMPRESSION_GZIP) {
        stream = [[GZipOutputStream alloc] initWithOutputStream:stream];
    }
    
    // Write the inner header data.
    if (dbVersion >= KDBX40_VERSION) {   // KDBX 4
        [self writeInnerHeader:stream withTree:tree];
    }
    
    // Serialize the XML
    Kdb4Persist *persist = [[Kdb4Persist alloc] initWithTree:tree outputStream:stream randomStream:randomStream];
    [persist persist];
    
    // Close the output stream
    [stream close];

#if TARGET_OS_IPHONE
    // Write to the file on iOS
    if (![outputStream.data writeToFile:filename options:NSDataWritingFileProtectionComplete error:nil]) {
        @throw [NSException exceptionWithName:@"IOError" reason:@"Failed to write file" userInfo:nil];
    }
#else
    // Write to the file on MacOS
    if (![outputStream.data writeToFile:filename options:NSDataWritingAtomic error:nil]) {
        @throw [NSException exceptionWithName:@"IOError" reason:@"Failed to write file" userInfo:nil];
    }
#endif

}

- (void)writeHeaderField:(OutputStream*)outputStream headerId:(uint8_t)headerId data:(const void*)data length:(uint16_t)length {
    
    [outputStream writeInt8:headerId];
    
    if (dbVersion < KDBX40_VERSION) {
        [outputStream writeInt16:CFSwapInt16HostToLittle(length)];
    } else {
        [outputStream writeInt32:CFSwapInt32HostToLittle(length)];
    }
    
    if (length > 0) {
        [outputStream write:data length:length];
    }
}

- (void)writeHeader:(OutputStream*)outputStream withTree:(Kdb4Tree*)tree {
    uint8_t buffer[16];
    uint32_t i32;
    uint64_t i64;
    
    // Signature and version
    [outputStream writeInt32:CFSwapInt32HostToLittle(KDB4_SIG1)];
    [outputStream writeInt32:CFSwapInt32HostToLittle(KDB4_SIG2)];
    [outputStream writeInt32:CFSwapInt32HostToLittle(dbVersion)];

    [tree.encryptionAlgorithm getBytes:buffer length:16];
    [self writeHeaderField:outputStream headerId:HEADER_CIPHERID data:buffer length:16];
    
    i32 = CFSwapInt32HostToLittle(tree.compressionAlgorithm);
    [self writeHeaderField:outputStream headerId:HEADER_COMPRESSION data:&i32 length:4];
    
    [self writeHeaderField:outputStream headerId:HEADER_MASTERSEED data:masterSeed.bytes length:masterSeed.length];
    
    if (dbVersion < KDBX40_VERSION) {
        NSData *seedData = (NSData *) tree.kdfParams[ KDF_AES_KEY_SEED ];
        
        [self writeHeaderField:outputStream headerId:HEADER_TRANSFORMSEED data:seedData.bytes length:seedData.length];
        
        uint64_t rounds = [tree.kdfParams[ KDF_AES_KEY_ROUNDS ] unsignedLongLongValue];
        i64 = CFSwapInt64HostToLittle(rounds);
        [self writeHeaderField:outputStream headerId:HEADER_TRANSFORMROUNDS data:&i64 length:8];
    } else {
        NSData *vdBytes = [tree.kdfParams serialize];
        [self writeHeaderField:outputStream headerId:HEADER_KDFPARMETERS data:vdBytes.bytes length:vdBytes.length];
    }
    
    if (encryptionIv.length > 0) {
        [self writeHeaderField:outputStream headerId:HEADER_ENCRYPTIONIV data:encryptionIv.bytes length:encryptionIv.length];
    }
    
    if (dbVersion < KDBX40_VERSION) {
        [self writeHeaderField:outputStream headerId:HEADER_PROTECTEDKEY data:protectedStreamKey.bytes length:protectedStreamKey.length];
        
        [self writeHeaderField:outputStream headerId:HEADER_STARTBYTES data:streamStartBytes.bytes length:streamStartBytes.length];
        
        i32 = CFSwapInt32HostToLittle(CSR_SALSA20);
        [self writeHeaderField:outputStream headerId:HEADER_RANDOMSTREAMID data:&i32 length:4];
    } else {
        if ([tree.customPluginData count] > 0) {
            NSData *vdBytes = [tree.customPluginData serialize];
            [self writeHeaderField:outputStream headerId:HEADER_PUBLICCUSTOM data:vdBytes.bytes length:vdBytes.length];
        }
    }

        // Write EOH record
    buffer[0] = '\r';
    buffer[1] = '\n';
    buffer[2] = '\r';
    buffer[3] = '\n';
    [self writeHeaderField:outputStream headerId:HEADER_EOH data:buffer length:4];
}

- (void)writeInnerHeader:(OutputStream*)outputStream withTree:(Kdb4Tree*)tree {
    uint8_t buffer[16];
    uint32_t i32;
    
     // Only KDBX 4 files use the inner header so random stream is always ChaCha20
    i32 = CFSwapInt32HostToLittle(CSR_CHACHA20);
    [self writeHeaderField:outputStream headerId:INNER_HEADER_RANDOMSTREAMID data:&i32 length:4];

    [self writeHeaderField:outputStream headerId:INNER_HEADER_RANDOMSTREAMKEY data:protectedStreamKey.bytes length:protectedStreamKey.length];

    for (NSData *bdata in tree.headerBinaries) {
        [self writeHeaderField:outputStream headerId:INNER_HEADER_BINARY data:bdata.bytes length:bdata.length];
    }
    
    [self writeHeaderField:outputStream headerId:HEADER_EOH data:buffer length:0];
}

- (NSData *)computeHashOfHeaderData:(NSData *)headerData {
    uint8_t hash[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256(headerData.bytes, (CC_LONG)headerData.length, hash);
    return [NSData dataWithBytes:hash length:sizeof(hash)];
}

- (void)newFile:(NSString*)fileName withPassword:(KdbPassword*)kdbPassword {
    NSDate *currentTime = [NSDate date];

    Kdb4Tree *tree = [[Kdb4Tree alloc] init];
    tree.generator = @"MiniKeePass";
    tree.databaseName = @"";
    tree.databaseNameChanged = currentTime;
    tree.databaseDescription = @"";
    tree.databaseDescriptionChanged = currentTime;
    tree.defaultUserName = @"";
    tree.defaultUserNameChanged = currentTime;
    tree.maintenanceHistoryDays = 365;
    tree.color = @"";
    tree.masterKeyChanged = currentTime;
    tree.masterKeyChangeRec = -1;
    tree.masterKeyChangeForce = -1;
    tree.protectTitle = NO;
    tree.protectUserName = NO;
    tree.protectPassword = YES;
    tree.protectUrl = NO;
    tree.protectNotes = NO;
    tree.recycleBinEnabled = YES;
    tree.recycleBinUuid = [KdbUUID nullUuid];
    tree.recycleBinChanged = currentTime;
    tree.entryTemplatesGroup = [KdbUUID nullUuid];
    tree.entryTemplatesGroupChanged = currentTime;
    tree.historyMaxItems = 10;
    tree.historyMaxSize = 6 * 1024 * 1024; // 6 MB
    tree.lastSelectedGroup = [KdbUUID nullUuid];
    tree.lastTopVisibleGroup = [KdbUUID nullUuid];
    
    // New KDBX 4 stuff.  Default to KDBX 3.1 format
    tree.forcedVersion = KDBX31_VERSION;
    tree.kdfParams = [KdbPassword getDefaultKDFParameters:[KdbUUID getAES_KDFUUID]];
    tree.encryptionAlgorithm = [KdbUUID getAESUUID];

    KdbGroup *parentGroup = [tree createGroup:nil];
    parentGroup.name = @"General";
    parentGroup.image = 48;
    tree.root = parentGroup;
    
    KdbGroup *group = [tree createGroup:parentGroup];
    group.name = @"Windows";
    group.image = 38;
    [parentGroup addGroup:group];
    
    group = [tree createGroup:parentGroup];
    group.name = @"Network";
    group.image = 3;
    [parentGroup addGroup:group];

    group = [tree createGroup:parentGroup];
    group.name = @"Internet";
    group.image = 1;
    [parentGroup addGroup:group];

    group = [tree createGroup:parentGroup];
    group.name = @"eMail";
    group.image = 19;
    [parentGroup addGroup:group];

    group = [tree createGroup:parentGroup];
    group.name = @"Homebanking";
    group.image = 37;
    [parentGroup addGroup:group];

    [self persist:tree file:fileName withPassword:kdbPassword];
}

- (uint32_t)getMinDatabaseVersion:(Kdb4Tree *)tree {
    if (tree.forcedVersion != 0) return tree.forcedVersion;
    
    if (![tree.encryptionAlgorithm isEqual:[KdbUUID getAESUUID]]) {
        return KDBX40_VERSION;
    }

    KdbUUID *KDFUuid = [[KdbUUID alloc] initWithData:tree.kdfParams[KDF_KEY_UUID_BYTES]];
    if (![KDFUuid isEqual:[KdbUUID getAES_KDFUUID]] ) {
        return KDBX40_VERSION;
    }
    
    if ([tree.customPluginData count] > 0) {
        return KDBX40_VERSION;
    }
    
    if ([self groupsHaveCustomData:(Kdb4Group*)tree.root]) {
        return KDBX40_VERSION;
    }
    
    return KDBX31_VERSION;
}

- (BOOL)groupsHaveCustomData:(Kdb4Group *) group {
    if ([group.customData count] > 0) return YES;
    
    for (Kdb4Group* g in group.groups) {
        if ([self groupsHaveCustomData:g]) return YES;
    }
    
    for (Kdb4Entry* e in group.entries) {
        if ([e.customData count] > 0) return YES;
    }
    
    return NO;
}

@end
