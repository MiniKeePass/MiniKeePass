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

#import "Base64Test.h"
#import "Base64.h"

@implementation Base64Test

- (void)testBase64 {
    // Prepare some test data
    uint8_t testBuffer[1024];
    for (int i = 0; i < 1024; i++) {
        testBuffer[i] = i;
    }
    
    NSData *encoded = [Base64 encode:[NSData dataWithBytes:testBuffer length:1024]];
    NSString *str = [[NSString alloc] initWithBytes:encoded.bytes length:encoded.length encoding:NSASCIIStringEncoding];
    NSLog(@"Base64 |%@|", str);
    NSData *decoded = [Base64 decode:encoded];
    
    STAssertTrue(decoded.length == 1024, @"Decoded length not equal to test data length (%d)", decoded.length);
    
    // Check if the streams differ
    uint8_t *buffer = (uint8_t*)decoded.bytes;
    for (int i = 0; i < 1024; i++) {
        if (testBuffer[i] != buffer[i]) {
            STAssertFalse(true, @"Data does not match at index %d (%d != %d)", i, testBuffer[i], buffer[i]);
            break;
        }
    }
}

@end
