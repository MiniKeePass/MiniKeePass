//
//  DataOutputStream.h
//  MobileKeePass
//
//  Created by Jason Rush on 5/22/11.
//  Copyright 2011 Self. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OutputStream.h"

@interface DataOutputStream : OutputStream {
    NSMutableData *data;
}

@property (nonatomic, readonly) NSMutableData *data;

@end
