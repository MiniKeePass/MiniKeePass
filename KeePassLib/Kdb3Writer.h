//
//  Kdb3Persist.h
//  KeePass2
//
//  Created by Qiang Yu on 2/16/10.
//  Copyright 2010 Qiang Yu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KdbWriter.h"
#import "KdbPassword.h"
#import "Kdb3Node.h"

@interface Kdb3Writer : NSObject<KdbWriter> {
    KdbPassword *kdbPassword;
    uint8_t encryptionIv[16];
}

- (void)newFile:(NSString*)fileName withPassword:(NSString*)password;

@end
