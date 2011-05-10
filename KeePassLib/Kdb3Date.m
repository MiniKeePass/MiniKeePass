//
//  Kdb3DateUtil.m
//  KeePass2
//
//  Created by Qiang Yu on 2/13/10.
//  Copyright 2010 Qiang Yu. All rights reserved.
//

#import "Kdb3Date.h"


@implementation Kdb3Date

+(void)date:(uint8_t *)date fromPacked:(uint8_t *)buffer{
	uint32_t dw1, dw2, dw3, dw4, dw5;
	dw1 = (uint32_t)buffer[0]; dw2 = (uint32_t)buffer[1]; dw3 = (uint32_t)buffer[2];
	dw4 = (uint32_t)buffer[3]; dw5 = (uint32_t)buffer[4];
	int y = (dw1 << 6) | (dw2 >> 2);
	int mon = ((dw2 & 0x00000003) << 2) | (dw3 >> 6);
	int d = (dw3 >> 1) & 0x0000001F;
	int h = ((dw3 & 0x00000001) << 4) | (dw4 >> 4);
	int min = ((dw4 & 0x0000000F) << 2) | (dw5 >> 6);
	int s = dw5 & 0x0000003F;
	
	date[0] = y/100; date[1] = y%100;
	date[2] = mon; date[3]=d;
	date[4]=h; date[5]=min; date[6]=s;
}

+(void)date:(uint8_t *)date ToPacked:(uint8_t *) buffer{
	uint32_t y = date[0]*100+date[1], mon = date[2], d=date[3], h=date[4], min=date[5], s=date[6];
	buffer[0] = (uint8_t)(((uint32_t)y >> 6) & 0x0000003F);
	buffer[1] = (uint8_t)((((uint32_t)y & 0x0000003F) << 2) | (((uint32_t)mon >> 2) & 0x00000003));
	buffer[2] = (uint8_t)((((uint32_t)mon & 0x00000003) << 6) | (((uint32_t)d & 0x0000001F) << 1) | (((uint32_t)h >> 4) & 0x00000001));
	buffer[3] = (uint8_t)((((uint32_t)h & 0x0000000F) << 4) | (((uint32_t)min >> 2) & 0x0000000F));
	buffer[4] = (uint8_t)((((uint32_t)min & 0x00000003) << 6) | ((uint32_t)s & 0x0000003F));	
}

+(void)date:(uint8_t *)date fromNSDate:(NSDate *)nsDate{
	NSCalendar *calendar = [NSCalendar currentCalendar];
	NSDateComponents *dateComponents = [calendar components:( NSYearCalendarUnit | NSMonthCalendarUnit |  NSDayCalendarUnit|NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit ) fromDate:nsDate];
	date[0] = [dateComponents year]/100;
	date[1] = [dateComponents year]%100;
	date[2] = [dateComponents month];
	date[3] = [dateComponents day];
	date[4] = [dateComponents hour];
	date[5] = [dateComponents minute];
	date[6] = [dateComponents second];
	
	DLog(@"-->%d", date[0]);
	DLog(@"-->%d", date[1]);
	DLog(@"-->%d", date[2]);
	DLog(@"-->%d", date[3]);
	DLog(@"-->%d", date[4]);
	DLog(@"-->%d", date[5]);
	DLog(@"-->%d", date[6]);	
}

@end
