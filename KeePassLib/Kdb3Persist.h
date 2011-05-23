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
    Kdb3Tree *_tree;
    OutputStream *outputStream;
    NSInteger _groupId;
}

@property(nonatomic, retain) KdbTree *_tree;

- (id)initWithTree:(Kdb3Tree*)tree andOutputStream:(OutputStream*)stream;
- (void)persist;

@end
