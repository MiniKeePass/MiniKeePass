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
    
    ByteBuffer * _encryptionIV, * _protectedStreamKey, * _streamStartBytes, *_masterSeed, *_transformSeed;
    uint32_t _compressionAlgorithm, _randomStreamID;
    uint64_t _rounds;

    KdbPassword * _password;
    Kdb4Tree * _tree;
}

@end
