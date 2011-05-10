//
//  AESInputSource.h
//  KeePass2
//
//  Created by Qiang Yu on 2/16/10.
//  Copyright 2010 Qiang Yu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonCryptor.h>

#import "DataSource.h"

#define AES_BUFFERSIZE 512*1024
/**
 * Attempts to streaming AES
 */
@interface AESDecryptSource : NSObject<InputDataSource> {
	id<InputDataSource> _source;
	CCCryptorRef _cryptorRef;
	
	uint8_t _inputBuffer[AES_BUFFERSIZE];	
	uint8_t _outputBuffer[AES_BUFFERSIZE];		
	uint32_t _bufferOffset;
	uint32_t _bufferSize;
	
	BOOL _eof;
}

@property(nonatomic, retain) id<InputDataSource> _source;

-(id)initWithInputSource:(id<InputDataSource>)source Keys:(uint8_t *)keys andIV:(uint8_t *)iv;
@end
