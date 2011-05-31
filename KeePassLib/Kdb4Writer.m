//
//  Kdb4Writer.m
//  MobileKeePass
//
//  Created by Jason Rush on 5/21/11.
//  Copyright 2011 Self. All rights reserved.
//

#import "Kdb4Writer.h"
#import "Kdb4Node.h"
#import "Kdb4Persist.h"
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

- (void)persist:(Kdb4Tree*)tree file:(NSString*)filename withPassword:(NSString*)password {
    // Configure the output stream
    DataOutputStream *outputStream = [[[DataOutputStream alloc] init] autorelease];
    
    // Write the header
    [self writeHeader:outputStream];
    
    // Create the encryption output stream
    NSData *key = [KdbPassword createFinalKey32ForPasssword:password encoding:NSUTF8StringEncoding kdbVersion:4 masterSeed:masterSeed transformSeed:transformSeed rounds:rounds];
    AesOutputStream *aesOutputStream = [[[AesOutputStream alloc] initWithOutputStream:outputStream key:key iv:encryptionIv] autorelease];
    
    // Write the stream start bytes
    [aesOutputStream write:streamStartBytes];
    
    // Create the hashed output stream
    HashedOutputStream *hashedOutputStream = [[[HashedOutputStream alloc] initWithOutputStream:aesOutputStream blockSize:1024*1024] autorelease];
    
    // Create the gzip output stream
    GZipOutputStream *gzipOutputStream = [[[GZipOutputStream alloc] initWithOutputStream:hashedOutputStream] autorelease];
    
    // Create the random stream
    id<RandomStream> randomStream = [[[Salsa20RandomStream alloc] init:protectedStreamKey] autorelease];
    
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

- (void)newFile:(NSString*)fileName withPassword:(NSString*)password {
    Kdb4Tree *tree = [[Kdb4Tree alloc] init];
    
    KdbGroup *parentGroup = [tree createGroup:nil];
    parentGroup.name = @"General";
    parentGroup.image = 48;
    [tree.root addGroup:parentGroup];
    
    KdbGroup *group = [tree createGroup:parentGroup];
    group.name = @"Windows";
    group.image = 38;
    [parentGroup addGroup:group];
    [group release];
    
    group = [tree createGroup:parentGroup];
    group.name = @"Network";
    group.image = 3;
    [parentGroup addGroup:group];
    [group release];
    
    group = [tree createGroup:parentGroup];
    group.name = @"Internet";
    group.image = 1;
    [parentGroup addGroup:group];
    [group release];
    
    group = [tree createGroup:parentGroup];
    group.name = @"eMail";
    group.image = 19;
    [parentGroup addGroup:group];
    [group release];
    
    group = [tree createGroup:parentGroup];
    group.name = @"Homebanking";
    group.image = 37;
    [parentGroup addGroup:group];
    [group release];
    
    [self persist:tree file:fileName withPassword:password];
    
    [tree release];
    [parentGroup release];
}

@end
