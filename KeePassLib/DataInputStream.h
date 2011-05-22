//
//  DataInputStream.h
//  MobileKeePass
//
//  Created by Jason Rush on 5/22/11.
//  Copyright 2011 Self. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "InputStream.h"

@interface DataInputStream : InputStream {
    NSData *data;
    NSUInteger dataOffset;
}

- (id)initWithData:(NSData*)d;

@end
