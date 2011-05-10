//
//  Node.m
//  KeePass2
//
//  Created by Qiang Yu on 2/10/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "Node.h"
#import "RandomStream.h"
#import "Base64.h"

#define A_PROTECTED "Protected"

@implementation Node

@synthesize _parent;
@synthesize _text;
@synthesize _name;


#pragma mark alloc/dealloc
-(id)initWithUTF8Name:(uint8_t *)name{
	NSString * value = [[NSString alloc]initWithUTF8String:(const char *)name];
	self = [self initWithStringName:value];
	[value release];
	return self;
}

-(id)initWithStringName:(NSString *)name{
	//DLog(@"+++ Node %@ created", name);
	if(self = [super init]){
		self._name = name;
		_text = [[NSMutableString alloc]initWithCapacity:64];
	}
	return self;
}

-(void)dealloc{
	//DLog(@"--- Node %@ deallocated", _name);
	[_parent release];
	[_children release];
	[_attributes release];
	[_text release];
	[_name release];
	[super dealloc];
}

-(void)addChild:(Node *) child{
	if(!_children) _children = [[NSMutableArray alloc]initWithCapacity:8];
	[_children addObject:child];
	child._parent = self;
}

-(void)removeChild:(Node *) child{
	[_children removeObject:child];
	child._parent = nil;
}

-(void)addAttribute:(NSString *)key value:(NSString *)value{
	if(!_attributes) _attributes = [[NSMutableDictionary alloc] initWithCapacity:2];
	[_attributes setObject:value forKey:key];
}

-(NSString *)description{
	return [NSString stringWithFormat:@"<%@>%@<%@/>", _name,_text, _name];	
}

-(NSArray *)_children{
	return _children;
}

-(NSDictionary *)_attributes{
	return _attributes;
}

//break cyclic references
-(void)breakCyclcReference{
	self._parent = nil;
	for(Node * child in _children){
		[child breakCyclcReference];
	}
}

//do nothing by default
-(void)postProcess:(id<RandomStream>)rs{
	if([(NSString *)[_attributes objectForKey:@A_PROTECTED] boolValue]){
		NSMutableData * data = [[NSMutableData alloc]initWithCapacity:[_text length]];
		[Base64 decode:_text to:data];
		[self._text setString:[rs xor:data]];
		[data release];
	}
}
@end
