//
//  KeeOtpAuthData.m
//  MiniKeePass
//
//  Created by Mark Hewett on 6/24/14.
//  Copyright (c) 2014 Self. All rights reserved.
//

#import "KeeOtpAuthData.h"

@implementation KeeOtpAuthData

- (id)initWithString:(NSString *)string {
    self = [super init];
    if (self) {
        NSArray *kvPairs = [string componentsSeparatedByString:@"&"];
        for (NSString *kvPair in kvPairs) {
            NSArray *parts = [kvPair componentsSeparatedByString:@"="];
            if ([parts count] == 2) {
                NSString *key = [parts objectAtIndex:0];
                NSString *value = [parts objectAtIndex:1];
                if ([key caseInsensitiveCompare:@"key"] == NSOrderedSame) {
                    _key = [value stringByReplacingOccurrencesOfString:@"%3d" withString:@"=" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [value length])];
                }
                else if ([key caseInsensitiveCompare:@"type"] == NSOrderedSame) {
                    _type = [value stringByReplacingOccurrencesOfString:@"%3d" withString:@"=" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [value length])];
                }
                else if ([key caseInsensitiveCompare:@"step"] == NSOrderedSame) {
                    _step = (uint32_t)[value integerValue];
                }
                else if ([key caseInsensitiveCompare:@"size"] == NSOrderedSame) {
                    _size = (uint32_t)[value integerValue];
                }
                else if ([key caseInsensitiveCompare:@"counter"] == NSOrderedSame) {
                    _counter = (uint32_t)[value integerValue];
                }
            }
        }
        if (_type == nil) {
            _type = @"totp";
        }
        if (_step == 0) {
            _step = 30;
        }
        if (_size == 0) {
            _size = 6;
        }
    }
    return self;
}

- (BOOL)isSupported {
    BOOL result = YES;
    if (_key == nil) {
        result = NO;
    }
    if ([self.type caseInsensitiveCompare:@"totp"] != NSOrderedSame) {
        result = NO;
    }
    return result;
}

@end
