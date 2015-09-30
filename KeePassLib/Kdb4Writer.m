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
#import "AesOutputStream.h"
#import "HashedOutputStream.h"
#import "GZipOutputStream.h"
#import "Salsa20RandomStream.h"
#import "UUID.h"
#import "Utils.h"
#import <CommonCrypto/CommonDigest.h>

#define DEFAULT_BIN_SIZE (32*1024)

@interface Kdb4Writer (PrivateMethods)
- (void)writeHeaderField:(OutputStream*)outputStream headerId:(uint8_t)headerId data:(const void*)data length:(uint16_t)length;
- (void)writeHeader:(OutputStream*)outputStream withTree:(Kdb4Tree*)tree;
@end

@implementation Kdb4Writer

- init {
    self = [super init];
    if (self) {
        masterSeed = [Utils randomBytes:32];
        transformSeed = [Utils randomBytes:32];
        encryptionIv = [Utils randomBytes:16];
        protectedStreamKey = [Utils randomBytes:32];
        streamStartBytes = [Utils randomBytes:32];
    }
    return self;
}

- (void)persist:(Kdb4Tree*)tree file:(NSString*)filename withPassword:(KdbPassword*)kdbPassword {
    // Update the generator
    tree.generator = @"MiniKeePass";

    // Configure the output stream
    DataOutputStream *outputStream = [[DataOutputStream alloc] init];
    
    // Write the header
    [self writeHeader:outputStream withTree:tree];

    // Compute a hash of the header data
    tree.headerHash = [self computeHashOfHeaderData:outputStream.data];
    
    // Create the encryption output stream
    NSData *key = [kdbPassword createFinalKeyForVersion:4 masterSeed:masterSeed transformSeed:transformSeed rounds:tree.rounds];
    AesOutputStream *aesOutputStream = [[AesOutputStream alloc] initWithOutputStream:outputStream key:key iv:encryptionIv];
    
    // Write the stream start bytes
    [aesOutputStream write:streamStartBytes];
    
    // Create the hashed output stream
    OutputStream *stream = [[HashedOutputStream alloc] initWithOutputStream:aesOutputStream blockSize:1024*1024];
    
    // Create the gzip output stream
    if (tree.compressionAlgorithm == COMPRESSION_GZIP) {
        stream = [[GZipOutputStream alloc] initWithOutputStream:stream];
    }
    
    // Create the random stream
    RandomStream *randomStream = [[Salsa20RandomStream alloc] init:protectedStreamKey];
    
    // Serialize the XML
    Kdb4Persist *persist = [[Kdb4Persist alloc] initWithTree:tree outputStream:stream randomStream:randomStream];
    [persist persist];
    
    // Close the output stream
    [stream close];

    // Write to the file
    if (![outputStream.data writeToFile:filename options:NSDataWritingFileProtectionComplete error:nil]) {
        @throw [NSException exceptionWithName:@"IOError" reason:@"Failed to write file" userInfo:nil];
    }
}

- (void)writeHeaderField:(OutputStream*)outputStream headerId:(uint8_t)headerId data:(const void*)data length:(uint16_t)length {
    [outputStream writeInt8:headerId];
    
    [outputStream writeInt16:CFSwapInt16HostToLittle(length)];
    
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
    [outputStream writeInt32:CFSwapInt32HostToLittle(KDB4_VERSION)];
    
    UUID *cipherUuid = [UUID getAESUUID];
    [cipherUuid getBytes:buffer length:16];
    [self writeHeaderField:outputStream headerId:HEADER_CIPHERID data:buffer length:16];
    
    i32 = CFSwapInt32HostToLittle(tree.compressionAlgorithm);
    [self writeHeaderField:outputStream headerId:HEADER_COMPRESSION data:&i32 length:4];
    
    [self writeHeaderField:outputStream headerId:HEADER_MASTERSEED data:masterSeed.bytes length:masterSeed.length];
    
    [self writeHeaderField:outputStream headerId:HEADER_TRANSFORMSEED data:transformSeed.bytes length:transformSeed.length];
    
    i64 = CFSwapInt64HostToLittle(tree.rounds);
    [self writeHeaderField:outputStream headerId:HEADER_TRANSFORMROUNDS data:&i64 length:8];
    
    [self writeHeaderField:outputStream headerId:HEADER_ENCRYPTIONIV data:encryptionIv.bytes length:encryptionIv.length];
    
    [self writeHeaderField:outputStream headerId:HEADER_PROTECTEDKEY data:protectedStreamKey.bytes length:protectedStreamKey.length];
    
    [self writeHeaderField:outputStream headerId:HEADER_STARTBYTES data:streamStartBytes.bytes length:streamStartBytes.length];
    
    i32 = CFSwapInt32HostToLittle(CSR_SALSA20);
    [self writeHeaderField:outputStream headerId:HEADER_RANDOMSTREAMID data:&i32 length:4];
    
    buffer[0] = '\r';
    buffer[1] = '\n';
    buffer[2] = '\r';
    buffer[3] = '\n';
    [self writeHeaderField:outputStream headerId:HEADER_EOH data:buffer length:4];
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
    tree.recycleBinUuid = [UUID nullUuid];
    tree.recycleBinChanged = currentTime;
    tree.entryTemplatesGroup = [UUID nullUuid];
    tree.entryTemplatesGroupChanged = currentTime;
    tree.historyMaxItems = 10;
    tree.historyMaxSize = 6 * 1024 * 1024; // 6 MB
    tree.lastSelectedGroup = [UUID nullUuid];
    tree.lastTopVisibleGroup = [UUID nullUuid];

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

@end
