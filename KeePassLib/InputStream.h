//
//  InputStream.h
//  MobileKeePass
//
//  Created by Jason Rush on 5/22/11.
//  Copyright 2011 Self. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface InputStream : NSObject {
    
}

- (NSUInteger)read:(void*)bytes length:(NSUInteger)bytesLength;

- (uint8_t)readInt8;
- (uint16_t)readInt16;
- (uint32_t)readInt32;
- (uint64_t)readInt64;

- (void)close;

@end
