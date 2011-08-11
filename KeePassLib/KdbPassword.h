//
//  Password.h
//  KeePass2
//
//  Created by Qiang Yu on 1/5/10.
//  Copyright 2010 Qiang Yu. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KdbPassword : NSObject {
    NSData *masterKey;
    BOOL needsAdditionalHash;
}

- (id)initWithPassword:(NSString*)password encoding:(NSStringEncoding)encoding;
- (id)initWithKeyfile:(NSString*)filename;
- (id)initWithPassword:(NSString*)password encoding:(NSStringEncoding)encoding keyfile:(NSString*)filename;

- (NSData*)createFinalKeyForVersion:(uint8_t)version masterSeed:(NSData*)masterSeed transformSeed:(NSData*)transformSeed rounds:(uint64_t)rounds;

@end
