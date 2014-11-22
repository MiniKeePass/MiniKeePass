//
//  KeeOtpAuthData.h
//  MiniKeePass
//
//  Created by Mark Hewett on 6/24/14.
//  Copyright (c) 2014 Self. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KeeOtpAuthData : NSObject

- (id)initWithString:(NSString *)string;
- (BOOL)isSupported;

@property NSString *key;
@property NSString *type;
@property uint32_t step;
@property uint32_t size;
@property uint32_t counter;

@end
