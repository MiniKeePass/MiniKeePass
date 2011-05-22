//
//  AesStreamTest.m
//  MobileKeePass
//
//  Created by Jason Rush on 5/22/11.
//  Copyright 2011 Self. All rights reserved.
//

#import "AesStreamTest.h"
#import "AesOutputStream.h"
#import "DataOutputStream.h"
#import "AesInputStream.h"
#import "DataInputStream.h"
#import "Utils.h"

@implementation AesStreamTest

- (void)setUp {
    password = @"test";
    
    [Utils getRandomBytes:encryptionIv length:16];
    
    kdbPassword = [[KdbPassword alloc] initForEncryption:32];
    key = [kdbPassword createFinalKey32ForPasssword:password encoding:NSUTF8StringEncoding kdbVersion:4];
}

- (void)tearDown {
    [key release];
    [kdbPassword release];
}

- (void)testAesStream {
    DataOutputStream *dataOutputStream = [[DataOutputStream alloc] init];
    AesOutputStream *aesOutputStream = [[AesOutputStream alloc] initWithOutputStream:dataOutputStream key:key._bytes iv:encryptionIv];
    
    uint8_t outputBuffer[256];
    for (int i = 0; i < 256; i++) {
        outputBuffer[i] = i;
    }
    
    NSUInteger numWritten = [aesOutputStream write:outputBuffer length:256];
    STAssertTrue(numWritten == 256, @"Did not write expected number of bytes (%d)", numWritten);
    
    [aesOutputStream close];
    
    DataInputStream *dataInputStream = [[DataInputStream alloc] initWithData:dataOutputStream.data];
    AesInputStream *aesInputStream = [[AesInputStream alloc] initWithInputStream:dataInputStream key:key._bytes iv:encryptionIv];
    
    uint8_t inputBuffer[256];
    NSUInteger numRead = [aesInputStream read:inputBuffer length:256];
    STAssertTrue(numRead == 256, @"Did not read expected number of bytes (%d)", numRead);
    
    BOOL differs = NO;
    for (int i = 0; i < 256 && !differs; i++) {
        differs |= (outputBuffer[i] != inputBuffer[i]);
    }
    
    STAssertFalse(differs, @"Decrypted buffer does not match encrypted");
}

@end
