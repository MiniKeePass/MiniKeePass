//
//  KdbWriter.h
//  MobileKeePass
//
//  Created by Jason Rush on 5/21/11.
//  Copyright 2011 Self. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Kdb.h"

@protocol KdbWriter<NSObject>
- (void)persist:(KdbTree*)tree file:(NSString*)filename withPassword:(NSString*)password;
- (void)newFile:(NSString*)fileName withPassword:(NSString*)password;
@end
