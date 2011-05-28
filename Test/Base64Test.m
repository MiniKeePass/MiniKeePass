//
//  Base64Test.m
//  MobileKeePass
//
//  Created by Jason Rush on 5/27/11.
//  Copyright 2011 Self. All rights reserved.
//

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
