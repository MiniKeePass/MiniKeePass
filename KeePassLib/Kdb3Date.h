//
//  Kdb3DateUtil.h
//  KeePass2
//
//  Created by Qiang Yu on 2/13/10.
//  Copyright 2010 Qiang Yu. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Kdb3Date : NSObject {
    
}

+ (NSDate*)fromPacked:(uint8_t *)buffer;
+ (void)toPacked:(NSDate*)date bytes:(uint8_t*)bytes;

@end
