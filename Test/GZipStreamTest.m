//
//  GZipStreamTest.m
//  MobileKeePass
//
//  Created by Jason Rush on 5/25/11.
//  Copyright 2011 Self. All rights reserved.
//

#import "GZipStreamTest.h"
#import "GZipOutputStream.h"
#import "GZipInputStream.h"
#import "DataOutputStream.h"
#import "DataInputStream.h"

@implementation GZipStreamTest

- (void)testGZipStream {
    // Prepare some test data
    uint8_t outputBuffer[1024 * 1024];
    for (int i = 0; i < 1024 * 1024; i++) {
        outputBuffer[i] = i;
    }
    
    // Create the output stream
    DataOutputStream *dataOutputStream = [[DataOutputStream alloc] init];
    GZipOutputStream *gzipOutputStream = [[GZipOutputStream alloc] initWithOutputStream:dataOutputStream];
    
    // Write out 1MB of data 1024 bytes at a time
    for (int i = 0; i < 1024 * 1024; i += 1024) {
        NSUInteger numWritten = [gzipOutputStream write:(outputBuffer+i) length:1024];
        STAssertTrue(numWritten == 1024, @"Did not write expected number of bytes (%d)", numWritten);
    }
    
    [gzipOutputStream close];
    
    // Create the input stream from the output streams data
    DataInputStream *dataInputStream = [[DataInputStream alloc] initWithData:dataOutputStream.data];
    GZipInputStream *gzipInputStream = [[GZipInputStream alloc] initWithInputStream:dataInputStream];
    
    // Read in 1MB of data 512 blocks at a time
    uint8_t inputBuffer[1024 * 1024];
    for (int i = 0; i < 1024 * 1024; i += 512) {
        NSUInteger numRead = [gzipInputStream read:(inputBuffer+i) length:512];
        STAssertTrue(numRead == 512, @"Did not read expected number of bytes (%d)", numRead);
    }
    
    [gzipInputStream close];
    
    // Check if the streams differ
    BOOL differs = NO;
    for (int i = 0; i < 1024 * 1024 && !differs; i++) {
        differs |= (outputBuffer[i] != inputBuffer[i]);
    }
    
    STAssertFalse(differs, @"Streams do not match");
}

@end
