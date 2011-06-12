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
