//
//  Kdb4Writer.m
//  MobileKeePass
//
//  Created by Jason Rush on 5/21/11.
//  Copyright 2011 Self. All rights reserved.
//

#import "Kdb4Writer.h"
#import "Kdb4Node.h"
#import "DataOutputStream.h"
#import "HashedOutputStream.h"
#import "AesOutputStream.h"
#import "ByteBuffer.h"
#import "UUID.h"
#import "Utils.h"

#define DEFAULT_BIN_SIZE (32*1024)

@interface Kdb4Writer (PrivateMethods)
- (void)writeHeaderField:(OutputStream*)outputStream headerId:(uint8_t)headerId data:(void*)data length:(uint16_t)length;
- (void)writeHeader:(OutputStream*)outputStream;
@end

@implementation Kdb4Writer

- init {
    self = [super init];
    if (self) {
        // Initialize the KdbPassword for encryption
        kdbPassword = [[KdbPassword alloc] initForEncryption:32];
        
        // Setup the encryption initialization vector
        [Utils getRandomBytes:encryptionIv length:16];
        
        // Setup the protected stream key
        [Utils getRandomBytes:protectedStreamKey length:32];
        
        // Setup the stream start bytes
        [Utils getRandomBytes:streamStartBytes length:32];
    }
    return self;
}

- (void)dealloc {
    [kdbPassword dealloc];
    [super dealloc];
}

- (void)persist:(Kdb4Tree*)tree file:(NSString*)filename withPassword:(NSString*)password {
    // Configure the output stream
    DataOutputStream *outputStream = [[DataOutputStream alloc] init];
    
    // Write the header
    [self writeHeader:outputStream];
    
    // Create the hashed output stream
    HashedOutputStream *hashedOutputStream = [[HashedOutputStream alloc] initWithOutputStream:outputStream blockSize:1014*1024];
    
    // Create the encryption output stream
    ByteBuffer *finalKey = [kdbPassword createFinalKey32ForPasssword:password encoding:NSUTF8StringEncoding kdbVersion:4];
    AesOutputStream *aesOutputStream = [[AesOutputStream alloc] initWithOutputStream:hashedOutputStream key:finalKey._bytes iv:encryptionIv];
    [finalKey release];
    
    // Write the stream start bytes
    [aesOutputStream write:streamStartBytes length:32];
    
    // Serialize the XML
    [aesOutputStream write:[tree.document XMLData]];
    
    // Close the output stream
    [aesOutputStream close];
    
    // Write to the file
    if (![outputStream.data writeToFile:[filename stringByAppendingPathExtension:@"test.kdbx"] atomically:YES]) {
        @throw [NSException exceptionWithName:@"IOError" reason:@"Failed to write file" userInfo:nil];
    }
}

- (void)writeHeaderField:(OutputStream*)outputStream headerId:(uint8_t)headerId data:(void*)data length:(uint16_t)length {
    [outputStream writeInt8:headerId];
    
    [outputStream writeInt16:SWAP_INT16_HOST_TO_LE(length)];
    
    if (length > 0) {
        [outputStream write:data length:length];
    }
}

- (void)writeHeader:(OutputStream*)outputStream {
    uint8_t bytes[4];
    uint32_t i32;
    uint64_t i64;
    
    // Signature and version
    [outputStream writeInt32:SWAP_INT32_HOST_TO_LE(KDB4_SIG1)];
    [outputStream writeInt32:SWAP_INT32_HOST_TO_LE(KDB4_SIG2)];
    [outputStream writeInt32:SWAP_INT32_HOST_TO_LE(KDB4_VERSION)];
    
    UUID *cipherUuid = [UUID getAESUUID];
    [self writeHeaderField:outputStream headerId:HEADER_CIPHERID data:cipherUuid._bytes length:cipherUuid._size];
    
    // FIXME support gzip
    i32 = SWAP_INT32_HOST_TO_LE(COMPRESSION_NONE);
    [self writeHeaderField:outputStream headerId:HEADER_COMPRESSION data:&i32 length:4];
    
    [self writeHeaderField:outputStream headerId:HEADER_MASTERSEED data:kdbPassword._masterSeed._bytes length:kdbPassword._masterSeed._size];
    
    [self writeHeaderField:outputStream headerId:HEADER_TRANSFORMSEED data:kdbPassword._transformSeed._bytes length:kdbPassword._transformSeed._size];
    
    i64 = SWAP_INT64_HOST_TO_LE(kdbPassword._rounds);
    [self writeHeaderField:outputStream headerId:HEADER_TRANSFORMROUNDS data:&i64 length:8];
    
    [self writeHeaderField:outputStream headerId:HEADER_ENCRYPTIONIV data:encryptionIv length:16];
    
    [self writeHeaderField:outputStream headerId:HEADER_PROTECTEDKEY data:protectedStreamKey length:32];
    
    [self writeHeaderField:outputStream headerId:HEADER_STARTBYTES data:streamStartBytes length:32];
    
    i32 = SWAP_INT32_HOST_TO_LE(CSR_SALSA20);
    [self writeHeaderField:outputStream headerId:HEADER_RANDOMSTREAMID data:&i32 length:4];
    
    bytes[0] = '\r';
    bytes[1] = '\n';
    bytes[2] = '\r';
    bytes[3] = '\n';
    [self writeHeaderField:outputStream headerId:HEADER_EOH data:bytes length:4];
}

@end
