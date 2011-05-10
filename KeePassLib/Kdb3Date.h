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

//date[0] date[1] yyyy
//date[2] mm
//date[3] dd
//date[4] hh
//date[5] mi
//date[6] ss
+(void)date:(uint8_t *)date fromPacked:(uint8_t *)buffer;
+(void)date:(uint8_t *)date ToPacked:(uint8_t *) buffer;
+(void)date:(uint8_t *)date fromNSDate:(NSDate *)nsDate;
@end
