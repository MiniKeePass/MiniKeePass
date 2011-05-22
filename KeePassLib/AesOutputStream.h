//
//  AesOutputStream.h
//  MobileKeePass
//
//  Created by Jason Rush on 5/22/11.
//  Copyright 2011 Self. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonCryptor.h>
#import <CommonCrypto/CommonDigest.h>
#import "OutputStream.h"

@interface AesOutputStream : OutputStream {
    OutputStream *outputStream;
    
    CCCryptorRef cryptorRef;
    
    uint32_t bufferCapacity;
    uint8_t *buffer;
}

- (id)initWithOutputStream:(OutputStream*)stream key:(const void*)key iv:(const void*)iv;

@end
