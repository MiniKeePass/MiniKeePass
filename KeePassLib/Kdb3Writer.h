//
//  Kdb3Persist.h
//  KeePass2
//
//  Created by Qiang Yu on 2/16/10.
//  Copyright 2010 Qiang Yu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KdbWriter.h"
#import "Kdb3Node.h"

@interface Kdb3Writer : NSObject<KdbWriter> {
    NSData *masterSeed;
    NSData *encryptionIv;
    NSData *transformSeed;
    uint32_t rounds;
}

@end
