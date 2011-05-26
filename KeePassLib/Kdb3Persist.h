//
//  Kdb3Persist.h
//  KeePass2
//
//  Created by Qiang Yu on 2/22/10.
//  Copyright 2010 Qiang Yu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Kdb3Node.h"
#import "OutputStream.h"

@interface Kdb3Persist : NSObject {
    Kdb3Tree *tree;
    OutputStream *outputStream;
}

- (id)initWithTree:(Kdb3Tree*)tree andOutputStream:(OutputStream*)stream;
- (void)persist;

@end
