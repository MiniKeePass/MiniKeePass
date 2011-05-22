//
//  Kdb4Writer.m
//  MobileKeePass
//
//  Created by Jason Rush on 5/21/11.
//  Copyright 2011 Self. All rights reserved.
//

#import "Kdb4Writer.h"
#import "Kdb4Node.h"
#import "ByteBuffer.h"
#import "UUID.h"
#import "Utils.h"

#define DEFAULT_BIN_SIZE (32*1024)

@interface Kdb4Writer (PrivateMethods)
- (void)writeHeaderField:(NSMutableData*)buffer headerId:(uint8_t)headerId data:(void*)data length:(uint16_t)length;
- (void)writeHeader:(NSMutableData*)buffer;
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
    // Write the header
    NSMutableData *data = [[NSMutableData alloc] initWithCapacity:DEFAULT_BIN_SIZE];
    [self writeHeader:data];
    
    // FIXME this is just for testing
    [data writeToFile:[filename stringByAppendingPathExtension:@".bin"] atomically:YES];

    // Generate the encryption key
    ByteBuffer *finalKey = [[kdbPassword createFinalKey32ForPasssword:password encoding:NSUTF8StringEncoding kdbVersion:4] autorelease];
    
    // TODO serialize XML and encrypt
}

- (void)writeHeaderField:(NSMutableData*)buffer headerId:(uint8_t)headerId data:(void*)data length:(uint16_t)length {
    [buffer appendBytes:&headerId length:1];
    
    uint16_t i16 = SWAP_INT16_HOST_TO_LE(length);
    [buffer appendBytes:&i16 length:2];
    
    if (length > 0) {
        [buffer appendBytes:data length:length];
    }
}

- (void)writeHeader:(NSMutableData*)buffer {
    uint8_t bytes[12];
    uint32_t i32;
    uint64_t i64;
    
    // Signature and version
    *((uint32_t*)(bytes)) = SWAP_INT32_HOST_TO_LE(KDB4_SIG1);
    *((uint32_t*)(bytes+4)) = SWAP_INT32_HOST_TO_LE(KDB4_SIG2);
    *((uint32_t*)(bytes+8)) = SWAP_INT32_HOST_TO_LE(KDB4_VERSION);
    [buffer appendBytes:bytes length:12];
    
    UUID *cipherUuid = [UUID getAESUUID];
    [self writeHeaderField:buffer headerId:HEADER_CIPHERID data:cipherUuid._bytes length:cipherUuid._size];
    
    // FIXME support gzip
    i32 = SWAP_INT32_HOST_TO_LE(COMPRESSION_NONE);
    [self writeHeaderField:buffer headerId:HEADER_COMPRESSION data:&i32 length:4];
    
    [self writeHeaderField:buffer headerId:HEADER_MASTERSEED data:kdbPassword._masterSeed._bytes length:kdbPassword._masterSeed._size];
    
    [self writeHeaderField:buffer headerId:HEADER_TRANSFORMSEED data:kdbPassword._transformSeed._bytes length:kdbPassword._transformSeed._size];
    
    i64 = SWAP_INT64_HOST_TO_LE(kdbPassword._rounds);
    [self writeHeaderField:buffer headerId:HEADER_TRANSFORMROUNDS data:&i64 length:8];
    
    [self writeHeaderField:buffer headerId:HEADER_ENCRYPTIONIV data:encryptionIv length:16];
    
    [self writeHeaderField:buffer headerId:HEADER_PROTECTEDKEY data:protectedStreamKey length:32];
    
    [self writeHeaderField:buffer headerId:HEADER_STARTBYTES data:streamStartBytes length:32];
    
    i32 = SWAP_INT32_HOST_TO_LE(CSR_SALSA20);
    [self writeHeaderField:buffer headerId:HEADER_RANDOMSTREAMID data:&i32 length:4];
    
    bytes[0] = '\r';
    bytes[1] = '\n';
    bytes[2] = '\r';
    bytes[3] = '\n';
    [self writeHeaderField:buffer headerId:HEADER_EOH data:bytes length:4];
}

@end
