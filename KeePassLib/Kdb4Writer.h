//
//  Kdb4Writer.h
//  MobileKeePass
//
//  Created by Jason Rush on 5/21/11.
//  Copyright 2011 Self. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KdbWriter.h"
#import "KdbPassword.h"
#import "Kdb4Node.h"

@interface Kdb4Writer : NSObject<KdbWriter> {
    NSData *masterSeed;
    NSData *transformSeed;
    uint64_t rounds;
    NSData *encryptionIv;
    NSData *protectedStreamKey;
    NSData *streamStartBytes;
}

@end
