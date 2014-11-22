//
//  KdbEntry+KdbEntry_MKPAdditions.m
//  MiniKeePass
//
//  Created by Mark Hewett on 6/24/14.
//  Copyright (c) 2014 Self. All rights reserved.
//

#import <objc/runtime.h>

#import "KdbEntry+MKPAdditions.h"
#import "AGClock+MKPAdditions.h"
#import "Kdb4Node.h"
#import "AeroGearOTP.h"
#import "KeeOtpAuthData.h"

// See http://stackoverflow.com/a/9987819/2278086

@interface KdbEntryMKPAdditionIVars : NSObject
+ (KdbEntryMKPAdditionIVars *)fetch:(id)targetInstance;
- (void)clear;
@property KeeOtpAuthData *otpAuthData;
@property BOOL isUpdated;
@property uint64_t lastOtpInterval;
@property NSString *lastOtp;
@end

@implementation KdbEntryMKPAdditionIVars

+ (KdbEntryMKPAdditionIVars *)fetch:(id)targetInstance {
    static void *compactFetchIVarKey = &compactFetchIVarKey;
    KdbEntryMKPAdditionIVars *ivars = objc_getAssociatedObject(targetInstance, &compactFetchIVarKey);
    if (ivars == nil) {
        ivars = [[KdbEntryMKPAdditionIVars alloc] init];
        objc_setAssociatedObject(targetInstance, &compactFetchIVarKey, ivars, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return ivars;
}

- (id)init {
    self = [super init];
    if (self) {
        _isUpdated = YES;
    }
    return self;
}

- (void)clear {
    self.otpAuthData = nil;
    self.lastOtpInterval = 0;
    self.lastOtp = 0;
}

@end

@implementation KdbEntry (MKPAdditions)

- (NSString *)getOtp {
    
    KdbEntryMKPAdditionIVars *ivars = [KdbEntryMKPAdditionIVars fetch:self];
    
    if (ivars.isUpdated) {
        
        NSLog(@"Looking for OTP auth data");
        
        [ivars clear];
    
        NSString *otpAuthDataString = [self getOtpDataFromStringFields];
        if (otpAuthDataString == nil && self.notes != nil) {
            otpAuthDataString = [self getOtpDataFromNotes];
        }
        if (otpAuthDataString != nil) {
            ivars.otpAuthData = [[KeeOtpAuthData alloc] initWithString:otpAuthDataString];
        }
        
        ivars.isUpdated = NO;
        
    }
    
    NSString *otp = @"";
    
    if (ivars.otpAuthData != nil) {
        if (ivars.otpAuthData.isSupported) {
            AGClock *clock = [[AGClock alloc] initWithTimeStep:ivars.otpAuthData.step];
            if (clock.currentInterval != ivars.lastOtpInterval) {
                // Need to generate the current OTP
                NSLog(@"Updating OTP");
                NSData *secret = [AGBase32 base32Decode:[ivars.otpAuthData key]];
                if (secret != nil) {
                    AGTotp *generator = [[AGTotp alloc] initWithSecret:secret tokenLength:ivars.otpAuthData.size hashAlg:SHA1 timeStep:ivars.otpAuthData.step];
                    otp = [generator generateOTP];
                    ivars.lastOtp = otp;
                    ivars.lastOtpInterval = clock.currentInterval;
                    NSLog(@"OTP: %@", otp);
                }
                else {
                    otp = @"Bad Key";
                }
            }
            else {
                otp = ivars.lastOtp;
            }
        }
        else {
            otp = @"Not Supported";
        }
    }
    
    return otp;
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

- (NSUInteger)getOtpTimeRemaining {
    KdbEntryMKPAdditionIVars *ivars = [KdbEntryMKPAdditionIVars fetch:self];
    if (ivars.otpAuthData != nil && ivars.otpAuthData.isSupported) {
        AGClock *clock = [[AGClock alloc] initWithTimeStep:ivars.otpAuthData.step];
        return clock.timeRemainingInCurrentInterval;
    }
    return 0;
}

- (void)setIsUpdated {
    [KdbEntryMKPAdditionIVars fetch:self].isUpdated = YES;
}

@end
