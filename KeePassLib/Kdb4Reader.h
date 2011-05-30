//
//  Kdb4.h
//  KeePass2
//
//  Created by Qiang Yu on 1/3/10.
//  Copyright 2010 Qiang Yu. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "KdbReader.h"
#import "Kdb4Node.h"
#import "UUID.h"

@interface Kdb4Reader : NSObject<KdbReader> {
    NSData *comment;
    UUID *cipherUuid;
    uint32_t compressionAlgorithm;
    NSData *masterSeed;
    NSData *transformSeed;
    uint64_t rounds;
    NSData *encryptionIv;
    NSData *protectedStreamKey;
    NSData *streamStartBytes;
    uint32_t randomStreamID;
}

@end
