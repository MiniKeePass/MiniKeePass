//
//  Kdb4Persist.h
//  MobileKeePass
//
//  Created by Jason Rush on 5/26/11.
//  Copyright 2011 Self. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Kdb4Node.h"
#import "OutputStream.h"

@interface Kdb4Persist : NSObject {
    Kdb4Tree *tree;
    OutputStream *outputStream;
}

- (id)initWithTree:(Kdb4Tree*)tree andOutputStream:(OutputStream*)stream;
- (void)persist;

@end
