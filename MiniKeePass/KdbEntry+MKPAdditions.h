//
//  KdbEntry+KdbEntry_MKPAdditions.h
//  MiniKeePass
//
//  Created by Mark Hewett on 6/24/14.
//  Copyright (c) 2014 Self. All rights reserved.
//

#import "Kdb.h"

@interface KdbEntry (MKPAdditions)

- (NSString *)getOtp;
- (NSUInteger)getOtpTimeRemaining;
- (void)setIsUpdated;

@end
