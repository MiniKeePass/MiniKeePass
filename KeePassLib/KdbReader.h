//
//  KdbReader.h
//  KeePass2
//
//  Created by Qiang Yu on 3/6/10.
//  Copyright 2010 Qiang Yu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Kdb.h"
#import "KdbPassword.h"
#import "InputStream.h"

@protocol KdbReader<NSObject>
- (KdbTree*)load:(InputStream*)inputStream withPassword:(KdbPassword*)kdbPassword;
@end
