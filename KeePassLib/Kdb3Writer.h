//
//  Kdb3Persist.h
//  KeePass2
//
//  Created by Qiang Yu on 2/16/10.
//  Copyright 2010 Qiang Yu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AESEncryptSource.h"
#import "KdbPassword.h"
#import "Kdb3Node.h"

#define KDB3_SIG1 (0x9AA2D903)
#define KDB3_SIG2 (0xB54BFB65)

#define FLAG_SHA2     1
#define FLAG_RIJNDAEL 2
#define FLAG_ARCFOUR  4
#define FLAG_TWOFISH  8

#define KDB3_VER  (0x00030002)
#define KDB3_HEADER_SIZE (124)

@interface Kdb3Writer : NSObject {
}

- (void)persist:(Kdb3Tree*)tree file:(NSString *) fileName withPassword:(NSString *)password;
- (void)newFile:(NSString *)fileName withPassword:(NSString *)password;

@end
