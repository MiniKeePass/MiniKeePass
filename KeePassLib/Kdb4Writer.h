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
    KdbPassword *kdbPassword;
    uint8_t encryptionIv[16];
    uint8_t protectedStreamKey[32];
    uint8_t streamStartBytes[32];
}

@end
