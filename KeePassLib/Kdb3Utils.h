//
//  Kdb3Utils.h
//  MiniKeePass
//
//  Created by Jason Rush on 9/14/12.
//  Copyright (c) 2012 Self. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Kdb3Node.h"

@interface Kdb3Utils : NSObject

+ (NSData *)hashHeader:(kdb3_header_t *)header;

@end
