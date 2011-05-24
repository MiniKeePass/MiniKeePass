//
//  Password.h
//  KeePass2
//
//  Created by Qiang Yu on 1/5/10.
//  Copyright 2010 Qiang Yu. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KdbPassword : NSObject {
}

+ (NSData*)createFinalKey32ForPasssword:(NSString*)password encoding:(NSStringEncoding)encoding kdbVersion:(uint8_t)version masterSeed:(NSData*)masterSeed transformSeed:(NSData*)transformSeed rounds:(uint64_t)rounds;

@end
