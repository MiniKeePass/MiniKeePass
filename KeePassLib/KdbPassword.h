//
//  Password.h
//  KeePass2
//
//  Created by Qiang Yu on 1/5/10.
//  Copyright 2010 Qiang Yu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "VariantDictionary.h"
#import "UUID.h"

@interface KdbPassword : NSObject

- (id)initWithPassword:(NSString*)inPassword
      passwordEncoding:(NSStringEncoding)inPasswordEncoding
               keyFile:(NSString*)inKeyFile;

- (NSData*)createFinalKeyForVersion:(uint8_t)version
                         masterSeed:(NSData*)masterSeed
                      transformSeed:(NSData*)transformSeed
                             rounds:(uint64_t)rounds;

- (NSData*)createFinalKeyKDBX4:(VariantDictionary *)kdfparams
                    masterSeed:(uint8_t*)masterSeed
                     HmacKey64:(uint8_t*)hmackey64;

+ (VariantDictionary *) getDefaultKDFParameters:(KdbUUID*)uuid;
+ (void)checkKDFParameters:(VariantDictionary *)kdf;

@end

