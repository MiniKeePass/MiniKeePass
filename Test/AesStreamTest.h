//
//  AesStreamTest.h
//  MobileKeePass
//
//  Created by Jason Rush on 5/22/11.
//  Copyright 2011 Self. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>
#import "KdbPassword.h"

@interface AesStreamTest : SenTestCase {
    NSString *password;
    uint8_t encryptionIv[16];
    KdbPassword *kdbPassword;
    ByteBuffer *key;
}

- (void)testAesStream;

@end
