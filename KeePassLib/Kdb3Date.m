//
//  Kdb3DateUtil.m
//  KeePass2
//
//  Created by Qiang Yu on 2/13/10.
//  Copyright 2010 Qiang Yu. All rights reserved.
//

#import "Kdb3Date.h"

@implementation Kdb3Date

+ (NSDate*)fromPacked:(uint8_t*)buffer {
    uint32_t dw1, dw2, dw3, dw4, dw5;
    dw1 = (uint32_t)buffer[0]; dw2 = (uint32_t)buffer[1]; dw3 = (uint32_t)buffer[2];
    dw4 = (uint32_t)buffer[3]; dw5 = (uint32_t)buffer[4];
    int y = (dw1 << 6) | (dw2 >> 2);
    int mon = ((dw2 & 0x00000003) << 2) | (dw3 >> 6);
    int d = (dw3 >> 1) & 0x0000001F;
    int h = ((dw3 & 0x00000001) << 4) | (dw4 >> 4);
    int min = ((dw4 & 0x0000000F) << 2) | (dw5 >> 6);
    int s = dw5 & 0x0000003F;
    
    if (y == 2999 && mon == 12 && d == 28 && h == 23 && min == 59 && s == 59) {
        return nil;
    }
    
    NSDateComponents *dateComponents = [[NSDateComponents alloc] init];
    [dateComponents setYear:y];
    [dateComponents setMonth:mon];
    [dateComponents setDay:d];
    [dateComponents setHour:h];
    [dateComponents setMinute:min];
    [dateComponents setSecond:s];
    
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDate *date = [calendar dateFromComponents:dateComponents];
    
    return date;
}

+ (void)toPacked:(NSDate*)date bytes:(uint8_t*)bytes {
    uint32_t y;
    uint32_t mon;
    uint32_t d;
    uint32_t h;
    uint32_t min;
    uint32_t s;
    
    if (date != nil) {
        NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
        NSDateComponents *dateComponents = [calendar components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond) fromDate:date];
        
        y = (uint32_t)[dateComponents year];
        mon = (uint32_t)[dateComponents month];
        d = (uint32_t)[dateComponents day];
        h = (uint32_t)[dateComponents hour];
        min = (uint32_t)[dateComponents minute];
        s = (uint32_t)[dateComponents second];
    } else {
        y = 2999;
        mon = 12;
        d = 28;
        h = 23;
        min = 59;
        s = 59;
    }
    
    bytes[0] = (uint8_t)((y >> 6) & 0x0000003F);
    bytes[1] = (uint8_t)(((y & 0x0000003F) << 2) | ((mon >> 2) & 0x00000003));
    bytes[2] = (uint8_t)(((mon & 0x00000003) << 6) | ((d & 0x0000001F) << 1) | ((h >> 4) & 0x00000001));
    bytes[3] = (uint8_t)(((h & 0x0000000F) << 4) | ((min >> 2) & 0x0000000F));
    bytes[4] = (uint8_t)(((min & 0x00000003) << 6) | (s & 0x0000003F));
}

@end
