//
//  OutputStream.h
//  MobileKeePass
//
//  Created by Jason Rush on 5/22/11.
//  Copyright 2011 Self. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OutputStream : NSObject {
    
}

- (NSUInteger)write:(const void*)bytes length:(NSUInteger)bytesLength;
- (NSUInteger)write:(NSData*)data;

- (void)writeInt8:(uint8_t)value;
- (void)writeInt16:(uint16_t)value;
- (void)writeInt32:(uint32_t)value;
- (void)writeInt64:(uint64_t)value;

- (void)close;

@end
