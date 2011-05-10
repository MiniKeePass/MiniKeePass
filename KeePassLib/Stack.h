//
//  Stack.h
//  KeePass2
//
//  Created by Qiang Yu on 2/11/10.
//  Copyright 2010 Qiang Yu. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface Stack : NSObject {
	NSMutableArray * _stack;
	NSUInteger _length;
}

-(void)push:(id)obj;
-(id)pop;
-(id)peek;
-(BOOL)isEmpty;
-(void)clear;
@end
