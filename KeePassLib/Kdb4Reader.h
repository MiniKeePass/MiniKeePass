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

@interface Kdb4Reader : NSObject<KdbReader> {
    NSData *cipherUuid;
    NSData *encryptionIv;
    NSData *masterSeed;
    NSData *transformSeed;
    NSData *streamStartBytes;
    NSData *protectedStreamKey;
    NSData *comment;
    
    uint32_t compressionAlgorithm;
    uint32_t randomStreamID;
    uint64_t rounds;
    
    Kdb4Tree * _tree;
}

@end
