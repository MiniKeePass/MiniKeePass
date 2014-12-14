/*
 * Copyright 2014 Mark Hewett. All rights reserved.
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

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
