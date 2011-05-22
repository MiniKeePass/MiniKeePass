//
//  HashedStreamTest.m
//  MobileKeePass
//
//  Created by Jason Rush on 5/22/11.
//  Copyright 2011 Self. All rights reserved.
//

#import "HashedStreamTest.h"
#import "HashedOutputStream.h"
#import "HashedInputStream.h"
#import "DataOutputStream.h"
#import "DataInputStream.h"

@implementation HashedStreamTest

- (void)testHashedStream {
    // Prepare some data to encrypt
    uint8_t outputBuffer[1024*1024];
    for (int i = 0; i < 1024*1024; i++) {
        outputBuffer[i] = i;
    }
    
    // Create the output stream
    DataOutputStream *dataOutputStream = [[DataOutputStream alloc] init];
    HashedOutputStream *hashedOutputStream = [[HashedOutputStream alloc] initWithOutputStream:dataOutputStream blockSize:128];
    
    // Write out 1MB of data 1024 bytes at a time
    for (int i = 0; i < 1024*1024; i += 1024) {
        NSUInteger numWritten = [hashedOutputStream write:(outputBuffer+i) length:1024];
        STAssertTrue(numWritten == 1024, @"Did not write expected number of bytes (%d)", numWritten);
    }
    
    [hashedOutputStream close];
    
    // Create the input stream from the output streams data
    DataInputStream *dataInputStream = [[DataInputStream alloc] initWithData:dataOutputStream.data];
    HashedInputStream *hasedInputStream = [[HashedInputStream alloc] initWithInputStream:dataInputStream];
    
    // Read in 1MB of data 512 blocks at a time
    uint8_t inputBuffer[1024 * 1024];
    for (int i = 0; i < 1024*1024; i += 512) {
        NSUInteger numRead = [hasedInputStream read:(inputBuffer+i) length:512];
        STAssertTrue(numRead == 512, @"Did not read expected number of bytes (%d)", numRead);
    }
    
    [hasedInputStream close];
    
    // Check if the streams differ
    BOOL differs = NO;
    for (int i = 0; i < 1024 * 1024 && !differs; i++) {
        differs |= (outputBuffer[i] != inputBuffer[i]);
    }
    
    STAssertFalse(differs, @"Streams do not match");
}

@end
