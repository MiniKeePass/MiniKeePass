//
//  Stack.m
//  KeePass2
//
//  Created by Qiang Yu on 2/11/10.
//  Copyright 2010 Qiang Yu. All rights reserved.
//

#import "Stack.h"


@implementation Stack
#pragma mark alloc/dealloc
-(id)init{
	if(self=[super init]){
		_stack = [[NSMutableArray alloc]initWithCapacity:8];
		_length = 0;
	}
	return self;
}

-(void)dealloc{
	[_stack release];
	[super dealloc];
}

#pragma mark Stack Operations
-(void)push:(id)obj{
	[_stack addObject:obj];
	_length++;
}

-(id)pop{
	if(!_length) return nil;
	
	id value = [[[_stack objectAtIndex:(_length-1)] retain] autorelease];

	[_stack removeObjectAtIndex:(_length-1)]; 
	_length--;
	return value;
}

-(id)peek{
	if(!_length) return nil;
	return [_stack objectAtIndex:(_length-1)];
}

-(BOOL)isEmpty{
	return !_length;
}

-(void)clear{
	[_stack removeAllObjects];
	_length = 0;
}

@end
