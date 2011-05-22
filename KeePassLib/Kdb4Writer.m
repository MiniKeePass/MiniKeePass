//
//  Kdb4Writer.m
//  MobileKeePass
//
//  Created by Jason Rush on 5/21/11.
//  Copyright 2011 Self. All rights reserved.
//

#import "Kdb4Writer.h"
#import "KdbPassword.h"
#import "ByteBuffer.h"
#import "Utils.h"

#define DEFAULT_BIN_SIZE (32*1024)

@interface Kdb4Writer (PrivateMethods)
- (void)writeHeader:(NSMutableData*)buffer;
@end

@implementation Kdb4Writer

- (void)persist:(Kdb4Tree*)tree file:(NSString*)filename withPassword:(NSString*)password {
    // Write the header
    NSMutableData *data = [[NSMutableData alloc] initWithCapacity:DEFAULT_BIN_SIZE];
    [self writeHeader:data];
    
    // FIXME this is just for testing
    [data writeToFile:filename atomically:YES];

    // Generate the encryption key
    KdbPassword *kdbPassword = [[[KdbPassword alloc] init] autorelease];
    ByteBuffer *finalKey = [[kdbPassword createFinalKey32ForPasssword:password coding:NSUTF8StringEncoding kdbVersion:4] autorelease];
    
    // TODO serialize XML and encrypt
}

- (void)writeHeader:(NSMutableData*)buffer {
    uint8_t bytes[1024];
    
    // Signature and version
    *((uint32_t*)(bytes)) = SWAP_INT32_HOST_TO_LE(KDB4_SIG1);      //0..3
    *((uint32_t*)(bytes+4)) = SWAP_INT32_HOST_TO_LE(KDB4_SIG2);    //4..7
    *((uint32_t*)(bytes+8)) = SWAP_INT32_HOST_TO_LE(KDB4_VERSION); //8..11
    [buffer appendBytes:bytes length:12];
    
    // TODO serialize other headers
}

@end
