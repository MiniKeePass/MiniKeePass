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

#import "KdbEntry+MKPAdditions.h"
#import "Kdb4Node.h"
#import "KeeOtpAuthData.h"

@implementation KdbEntry (MKPAdditions)

- (KeeOtpAuthData *)getOtpAuthData {

    NSLog(@"Looking for OTP auth data");
    
    NSString *otpAuthDataString = [self getOtpDataFromStringFields];
    if (otpAuthDataString == nil && self.notes != nil) {
        otpAuthDataString = [self getOtpDataFromNotes];
    }
    if (otpAuthDataString != nil) {
        NSLog(@"Found OTP auth data: %@", otpAuthDataString);
        return [[KeeOtpAuthData alloc] initWithString:otpAuthDataString];
    }
    
    return nil;
    
}

- (NSString *)getOtpDataFromStringFields {
    // Data could be in a string field for KDB4
    if ([self isKindOfClass:[Kdb4Entry class]]) {
        Kdb4Entry *kdb4Entry = (Kdb4Entry *)self;
        for (StringField *field in kdb4Entry.stringFields) {
            if (field.key && [field.key caseInsensitiveCompare:@"otp"] == NSOrderedSame) {
                return field.value;
            }
        }
    }
    return nil;
}

- (NSString *)getOtpDataFromNotes {
    NSError *error = NULL;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"otp:([^\\s]+)" options:NSRegularExpressionCaseInsensitive error:&error];
    if (error == nil) {
        NSArray *matches = [regex matchesInString:self.notes options:0 range:NSMakeRange(0, [self.notes length])];
        if ([matches count] > 0) {
            NSTextCheckingResult *firstMatch = [matches objectAtIndex:0];
            return [self.notes substringWithRange:[firstMatch rangeAtIndex:1]];
        }
    }
    return nil;
}

@end
