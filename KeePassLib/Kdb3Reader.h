//
//   Kdb3.h
//   KeePass
//
//   Created by Qiang Yu on 11/22/09.
//   Copyright 2009 Qiang Yu. All rights reserved.
//

/**
 * KDB3 Support
 */

#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonCryptor.h>

#import "KdbReader.h"
#import "Kdb3Node.h"

@interface Kdb3Reader : NSObject<KdbReader> {
    uint32_t flags;
    uint32_t version;
    NSData *masterSeed;
    NSData *encryptionIv;
    uint32_t numGroups;
    uint32_t numEntries;
    NSData *contentHash;
    NSData *transformSeed;
    uint32_t rounds;
}

@end



