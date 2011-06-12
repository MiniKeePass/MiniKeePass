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
