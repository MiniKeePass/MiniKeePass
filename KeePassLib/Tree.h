//
//  Tree.h
//  KeePass2
//
//  Created by Qiang Yu on 2/11/10.
//  Copyright 2010 Qiang Yu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Node.h"

/*Kdb tree*/
@interface Tree : NSObject {
	Node * _root;
}

@property(nonatomic, retain) Node * _root;
-(void)print;
@end
