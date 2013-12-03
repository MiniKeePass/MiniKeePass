//
//  Utils.h
//  KeePass2
//
//  Created by Qiang Yu on 1/7/10.
//  Copyright 2010 Qiang Yu. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Utils : NSObject {
}

+ (BOOL)emptyString:(NSString*)str;

+ (NSData*)randomBytes:(uint32_t)length;

+ (NSString*)hexDumpData:(NSData*)data;
+ (NSString*)hexDumpBytes:(const void *)buffer length:(ssize_t)length;

@end
