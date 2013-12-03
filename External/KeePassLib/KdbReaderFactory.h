//
//  KdbReaderFactory.h
//  KeePass2
//
//  Created by Qiang Yu on 3/8/10.
//  Copyright 2010 Qiang Yu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Kdb.h"
#import "KdbPassword.h"

@interface KdbReaderFactory : NSObject {

}

+ (KdbTree*)load:(NSString*)filename withPassword:(KdbPassword*)kdbPassword;

@end
