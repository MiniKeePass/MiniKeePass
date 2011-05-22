//
//  Kdb4.h
//  KeePass2
//
//  Created by Qiang Yu on 1/3/10.
//  Copyright 2010 Qiang Yu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ByteBuffer.h"
#import "UUID.h"
#import "KdbPassword.h"
#import "Kdb4Node.h"
#import "KdbReader.h"
#import "WrapperNSData.h"

@interface Kdb4Reader : NSObject<KdbReader> {
    UUID * _cipherUUID;
    
    ByteBuffer * _encryptionIV, * _protectedStreamKey, * _streamStartBytes;
    uint32_t _compressionAlgorithm, _randomStreamID;

    KdbPassword * _password;
    Kdb4Tree * _tree;
}

- (KdbTree*)load:(WrapperNSData *)input withPassword:(NSString*)password;

@end
