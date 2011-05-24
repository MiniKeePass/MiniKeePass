//
//  AesStreamTest.h
//  MobileKeePass
//
//  Created by Jason Rush on 5/22/11.
//  Copyright 2011 Self. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>

@interface AesStreamTest : SenTestCase {
    NSString *password;
    NSData *encryptionIv;
    NSData *masterSeed;
    NSData *transformSeed;
    uint32_t rounds;
    NSData *key;
}

- (void)testAesStream;

@end
