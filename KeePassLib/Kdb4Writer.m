/*
 * Copyright 2011 Jason Rush and John Flanagan. All rights reserved.
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

#define DEFAULT_BIN_SIZE (32*1024)

@interface Kdb4Writer (PrivateMethods)
- (void)writeHeaderField:(OutputStream*)outputStream headerId:(uint8_t)headerId data:(const void*)data length:(uint16_t)length;
- (void)writeHeader:(OutputStream*)outputStream;
@end

@implementation Kdb4Writer

- init {
    self = [super init];
    if (self) {
        masterSeed = [[Utils randomBytes:32] retain];
        transformSeed = [[Utils randomBytes:32] retain];
        rounds = 6000;
        encryptionIv = [[Utils randomBytes:16] retain];
        protectedStreamKey = [[Utils randomBytes:32] retain];
        streamStartBytes = [[Utils randomBytes:32] retain];
    }
    return self;
}

- (void)dealloc {
    [masterSeed release];
    [transformSeed release];
    [encryptionIv release];
    [protectedStreamKey release];
    [streamStartBytes release];
    [super dealloc];
}

- (void)persist:(Kdb4Tree*)tree file:(NSString*)filename withPassword:(KdbPassword*)kdbPassword {
    // Configure the output stream
    DataOutputStream *outputStream = [[[DataOutputStream alloc] init] autorelease];
    
    // Write the header
    [self writeHeader:outputStream];
    
    // Create the encryption output stream
    NSData *key = [kdbPassword createFinalKeyForVersion:4 masterSeed:masterSeed transformSeed:transformSeed rounds:rounds];
    AesOutputStream *aesOutputStream = [[[AesOutputStream alloc] initWithOutputStream:outputStream key:key iv:encryptionIv] autorelease];
    
    // Write the stream start bytes
    [aesOutputStream write:streamStartBytes];
    
    // Create the hashed output stream
    HashedOutputStream *hashedOutputStream = [[[HashedOutputStream alloc] initWithOutputStream:aesOutputStream blockSize:1024*1024] autorelease];
    
    // Create the gzip output stream
    GZipOutputStream *gzipOutputStream = [[[GZipOutputStream alloc] initWithOutputStream:hashedOutputStream] autorelease];
    
    // Create the random stream
    RandomStream *randomStream = [[[Salsa20RandomStream alloc] init:protectedStreamKey] autorelease];
    
    // Serialize the XML
    Kdb4Persist *persist = [[[Kdb4Persist alloc] initWithTree:tree outputStream:gzipOutputStream randomStream:randomStream] autorelease];
    [persist persist];
    
    // Close the output stream
    [gzipOutputStream close];
    
    // Write to the file
    if (![outputStream.data writeToFile:filename atomically:YES]) {
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

- (void)writeHeader:(OutputStream*)outputStream {
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
    
    // FIXME support gzip
    i32 = CFSwapInt32HostToLittle(COMPRESSION_GZIP);
    [self writeHeaderField:outputStream headerId:HEADER_COMPRESSION data:&i32 length:4];
    
    [self writeHeaderField:outputStream headerId:HEADER_MASTERSEED data:masterSeed.bytes length:masterSeed.length];
    
    [self writeHeaderField:outputStream headerId:HEADER_TRANSFORMSEED data:transformSeed.bytes length:transformSeed.length];
    
    i64 = CFSwapInt64HostToLittle(rounds);
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

- (void)newFile:(NSString*)fileName withPassword:(KdbPassword*)kdbPassword {
    DDXMLElement *docRoot = [DDXMLNode elementWithName:@"KeePassFile"];
    
    DDXMLElement *rootElement = [DDXMLElement elementWithName:@"Root"];
    [docRoot addChild:rootElement];
    
    DDXMLDocument *document = [[DDXMLDocument alloc] initWithRootElement:docRoot];
    Kdb4Tree *tree = [[Kdb4Tree alloc] initWithDocument:document];
    
    KdbGroup *parentGroup = [tree createGroup:nil];
    parentGroup.name = @"General";
    parentGroup.image = 48;
    [rootElement addChild:((Kdb4Group*)parentGroup).element];
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
    
    [tree release];
}

@end
