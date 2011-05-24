//
//  AesInputStream.h
//  MobileKeePass
//
//  Created by Jason Rush on 5/22/11.
//  Copyright 2011 Self. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonCryptor.h>
#import "InputStream.h"

#define AES_BUFFERSIZE (512*1024)

@interface AesInputStream : InputStream {
    InputStream *inputStream;
    
    CCCryptorRef cryptorRef;
    uint8_t inputBuffer[AES_BUFFERSIZE];   
    uint8_t outputBuffer[AES_BUFFERSIZE];
    uint32_t bufferOffset;
    uint32_t bufferSize;
    BOOL eof;
}

- (id)initWithInputStream:(InputStream*)stream key:(NSData*)key iv:(NSData*)iv;

@end
