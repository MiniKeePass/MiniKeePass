//
//  UUID.h
//  KeePass2
//
//  Created by Qiang Yu on 1/2/10.
//  Copyright 2010 Qiang Yu. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UUID : NSObject {
    CFUUIDRef uuid;
}

- (id)initWithBytes:(uint8_t*)bytes;
- (void)getBytes:(uint8_t*)bytes length:(NSUInteger)length;

+ (UUID*)getAESUUID;

@end
