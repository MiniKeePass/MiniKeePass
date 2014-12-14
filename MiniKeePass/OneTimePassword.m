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

#import "OneTimePassword.h"
#import "AeroGearOTP.h"
#import "AGClock+MKPAdditions.h"

@implementation OneTimePassword

- (id)initWithData:(KeeOtpAuthData *)data {
    if (self = [super init]) {
        otpAuthData = data;
        if (otpAuthData != nil && otpAuthData.isSupported) {
            secret = [AGBase32 base32Decode:[otpAuthData key]];
        }
        lastOtpInterval = 0;
        lastOtp = @"";
    }
    return self;
}

- (uint32_t)getStep {
    return otpAuthData.step;
}

- (NSString *)getOTP {
    
    NSString *otp = @"";
    
    if (otpAuthData != nil) {
        if (otpAuthData.isSupported) {
            AGClock *clock = [[AGClock alloc] initWithTimeStep:otpAuthData.step];
            if (clock.currentInterval != lastOtpInterval) {
                // Need to generate the current OTP
                if (secret != nil) {
                    NSLog(@"Updating OTP");
                    AGTotp *generator = [[AGTotp alloc] initWithSecret:secret tokenLength:otpAuthData.size hashAlg:SHA1 timeStep:otpAuthData.step];
                    otp = [generator generateOTP];
                    lastOtp = otp;
                    lastOtpInterval = clock.currentInterval;
                    NSLog(@"OTP: %@", otp);
                }
                else {
                    otp = @"Bad Key";
                }
            }
            else {
                otp = lastOtp;
            }
        }
        else {
            otp = @"Not Supported";
        }
    }
    
    return otp;

}

- (uint64_t)getOtpTimeRemaining {
    if (otpAuthData != nil && otpAuthData.isSupported) {
        AGClock *clock = [[AGClock alloc] initWithTimeStep:otpAuthData.step];
        return clock.timeRemainingInCurrentInterval;
    }
    return 0;
}

@end
