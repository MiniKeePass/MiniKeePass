//
//  AesStreamTest.m
//  MobileKeePass
//
//  Created by Jason Rush on 5/22/11.
//  Copyright 2011 Self. All rights reserved.
//

#import "AesStreamTest.h"
#import "AesOutputStream.h"
#import "AesInputStream.h"
#import "DataOutputStream.h"
#import "DataInputStream.h"
#import "KdbPassword.h"
#import "Utils.h"

@implementation AesStreamTest

- (void)setUp {
    password = @"test";
    
    encryptionIv = [[Utils randomBytes:16] retain];
    masterSeed = [[Utils randomBytes:32] retain];
    transformSeed = [[Utils randomBytes:32] retain];
    rounds = 6000;

    key = [[KdbPassword createFinalKey32ForPasssword:password encoding:NSUTF8StringEncoding kdbVersion:4 masterSeed:masterSeed transformSeed:transformSeed rounds:rounds] retain];
}

- (void)tearDown {
    [encryptionIv release];
    [masterSeed release];
    [transformSeed release];
    [key release];
}

- (void)testAesStream {
    // Prepare some data to encrypt
    uint8_t outputBuffer[1024*1024];
    for (int i = 0; i < 1024*1024; i++) {
        outputBuffer[i] = i;
    }
    
    // Create the output stream
    DataOutputStream *dataOutputStream = [[DataOutputStream alloc] init];
    AesOutputStream *aesOutputStream = [[AesOutputStream alloc] initWithOutputStream:dataOutputStream key:key iv:encryptionIv];
    
    // Write out 1MB of data 1024 bytes at a time
    for (int i = 0; i < 1024*1024; i += 1024) {
        NSUInteger numWritten = [aesOutputStream write:(outputBuffer+i) length:1024];
        STAssertTrue(numWritten == 1024, @"Did not write expected number of bytes (%d)", numWritten);
    }
    
    [aesOutputStream close];
    
    // Create the input stream from the output streams data
    DataInputStream *dataInputStream = [[DataInputStream alloc] initWithData:dataOutputStream.data];
    AesInputStream *aesInputStream = [[AesInputStream alloc] initWithInputStream:dataInputStream key:key iv:encryptionIv];
    
    // Read in 1MB of data 512 blocks at a time
    uint8_t inputBuffer[1024 * 1024];
    for (int i = 0; i < 1024*1024; i += 512) {
        NSUInteger numRead = [aesInputStream read:(inputBuffer+i) length:512];
        STAssertTrue(numRead == 512, @"Did not read expected number of bytes (%d)", numRead);
    }
    
    [aesInputStream close];
    
    // Check if the streams differ
    BOOL differs = NO;
    for (int i = 0; i < 1024 * 1024 && !differs; i++) {
        differs |= (outputBuffer[i] != inputBuffer[i]);
    }
    
    STAssertFalse(differs, @"Streams do not match");
}

@end
