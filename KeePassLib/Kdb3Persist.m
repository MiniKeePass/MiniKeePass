//
//  Kdb3Persist.m
//  KeePass2
//
//  Created by Qiang Yu on 2/22/10.
//  Copyright 2010 Qiang Yu. All rights reserved.
//

#import "Kdb3Persist.h"
#import "Stack.h"
#import "Utils.h"
#import "Kdb3Date.h"

@interface Kdb3Persist(PrivateMethods)
	-(void) persistGroups:(Kdb3Group *) root;
	-(void) persistEntries:(Kdb3Group *)root;
	-(void) persistMetaEntries:(Kdb3Group *)root;
	-(void) writeGroup:(Kdb3Group *)group;
	-(void) writeEntry:(Kdb3Entry *)entry;
	-(void) appendField:(uint16_t)type size:(uint32_t)size bytes:(void *)value;
@end

@implementation Kdb3Persist
@synthesize _tree;
@synthesize _enc;

-(id)initWithTree:(id<KdbTree>)tree andDest:(AESEncryptSource *)dest{
	if(self=[super init]){
		self._tree = tree;
		self._enc = dest;
		_groupId = 100;
	}
	return self;
}

-(void)dealloc{
	[_tree release];
	[_enc release];
	[super dealloc];
}

-(void) appendField:(uint16_t)type size:(uint32_t)size bytes:(void *)buffer{
	type = SWAP_INT16_HOST_TO_LE(type);
	size = SWAP_INT32_HOST_TO_LE(size);
	
	[_enc update:&type size:2];
	[_enc update:&size size:4];	
	if(size&&buffer) [_enc update:buffer size:size];
}

-(void)writeEntry:(Kdb3Entry *)entry{
	uint32_t tmp32;
	
	//uuid 2+4+16
	[self appendField:1 size:16 bytes:(void *)(entry._uuid._bytes)];
	
	//groupId
	tmp32 = SWAP_INT32_HOST_TO_LE(entry._parent._id);
	[self appendField:2 size:4 bytes:&tmp32];
	
	//image
	tmp32 = SWAP_INT32_HOST_TO_LE(entry._image);	
	[self appendField:3 size:4 bytes:&tmp32];
	
	//title
	if(![Utils emptyString:entry._title]){
		const char * tmp = [entry._title cStringUsingEncoding:NSUTF8StringEncoding];
		[self appendField:4 size:strlen(tmp)+1 bytes:(void *)tmp];	
	}
	
	//url
	if(![Utils emptyString:entry._url]){
		const char * tmp = [entry._url cStringUsingEncoding:NSUTF8StringEncoding];
		[self appendField:5 size:strlen(tmp)+1 bytes:(void *)tmp];	
	}
	
	//username
	if(![Utils emptyString:entry._username]){
		const char * tmp = [entry._username cStringUsingEncoding:NSUTF8StringEncoding];
		[self appendField:6 size:strlen(tmp)+1 bytes:(void *)tmp];	
	}
	
	//password
	if(![Utils emptyString:entry._password]){
		const char * tmp = [entry._password cStringUsingEncoding:NSUTF8StringEncoding];
		[self appendField:7 size:strlen(tmp)+1 bytes:(void *)tmp];	
	}
	
	//comment
	if(![Utils emptyString:entry._comment]){
		const char * tmp = [entry._comment cStringUsingEncoding:NSUTF8StringEncoding];
		[self appendField:8 size:strlen(tmp)+1 bytes:(void *)tmp];
	}
	
	uint8_t packedDate[5];
	
	//creation
	[Kdb3Date date:[entry getCreation] ToPacked:packedDate];	
	[self appendField:9 size:5 bytes:packedDate];
	
	//last mod
	[Kdb3Date date:[entry getLastMod] ToPacked:packedDate];	
	[self appendField:10 size:5 bytes:packedDate];
	
	//last access
	[Kdb3Date date:[entry getLastAccess] ToPacked:packedDate];		
	[self appendField:11 size:5 bytes:packedDate];
	
	//expire
	[Kdb3Date date:[entry getExpiry] ToPacked:packedDate];		
	[self appendField:12 size:5 bytes:packedDate];
	
	//binary desc
	if(![Utils emptyString:entry._binaryDesc]){
		const char * tmp = [entry._binaryDesc cStringUsingEncoding:NSUTF8StringEncoding];
		[self appendField:13 size:strlen(tmp)+1 bytes:(void *)tmp];		
	}
	
	//binary
	if(entry._binary && [entry._binary getSize]){
		[self appendField:14 size:[entry._binary getSize] bytes:[entry._binary getBinary]];		
	}
	
	[self appendField:0xFFFF size:0 bytes:nil];
	
	//so the total size for each entry is: (2+4)*15 + 16 + 4 + 4 + 5*4 + strings + binary = 134 + strings + binary 
}

-(void) writeGroup:(Kdb3Group *)group{
	//get the level/depth of the group
	uint16_t level = -1;	
	Kdb3Group * tmp = group;
	while(tmp._parent){
		level++;
		tmp = tmp._parent;
	}
	
	uint32_t tmp32;	
	//id 2+4+4
	tmp32 = SWAP_INT32_HOST_TO_LE(group._id);
	[self appendField:1 size:4 bytes:&tmp32];	
	
	
	//title 2+4+title size
	if(![Utils emptyString:group._title]){
		const char * title = [group._title cStringUsingEncoding:NSUTF8StringEncoding];
		[self appendField:2 size:strlen(title)+1 bytes:(void *)title];	
	}
	
	uint8_t packedDate[5];
	
	//creation date 2+4+5
	[Kdb3Date date:[group getCreation] ToPacked:packedDate];	
	[self appendField:3 size:5 bytes:packedDate];	
	
	//last mod 2+4+5
	[Kdb3Date date:[group getLastMod] ToPacked:packedDate];		
	[self appendField:3 size:5 bytes:packedDate];	
	
	//last access 2+4+5
	[Kdb3Date date:[group getLastAccess] ToPacked:packedDate];		
	[self appendField:3 size:5 bytes:packedDate];	
	
	//expire 2+4+5
	[Kdb3Date date:[group getExpiry] ToPacked:packedDate];		
	[self appendField:3 size:5 bytes:packedDate];	
	
	//image 2+4+4
	tmp32 = SWAP_INT32_HOST_TO_LE(group._image);
	[self appendField:7 size:4 bytes:&tmp32];	
	
	//level 2+4+2
	level = SWAP_INT16_HOST_TO_LE(level);
	[self appendField:8 size:2 bytes:&level];	
	
	//flags (unused) 2+4+4
	tmp32 = SWAP_INT32_HOST_TO_LE(group._flags);
	[self appendField:9 size:4 bytes:&tmp32];	
	
	//end of the group 2+4
	[self appendField:0xFFFF size:0 bytes:nil];	
	
	//so the size of each group is: 2+4+4 + (2+4+titleSize) + 4*(2+4+5) + 2+4+4 + 2+4+2 + 2+4+4 +2+4
	//=94+title size
}

-(void) persistGroups:(Kdb3Group *) root{
	Stack * stack = [[Stack alloc]init];
	for(Kdb3Group * group in root._subGroups){
		[stack push:group];
	}
	
	while(![stack isEmpty]){
		Kdb3Group * group = [stack pop];
		//assign unique group ids
		group._id = _groupId++;
		for(Kdb3Group * g in group._subGroups)
			[stack push:g];
		[self writeGroup:group];
	}
	[stack release];
}


-(void) persistEntries:(Kdb3Group *)root{
	Stack * stack = [[Stack alloc]init];
	for(Kdb3Group * group in root._subGroups){
		[stack push:group];
	}
	
	while(![stack isEmpty]){
		Kdb3Group * group = [stack pop];
		for(Kdb3Group * g in group._subGroups)
			[stack push:g];
		for(Kdb3Entry * e in group._entries){
			[self writeEntry:e];
		}
	}
	
	[stack release];
}

-(void) persistMetaEntries:(Kdb3Group *)root{
	Stack * stack = [[Stack alloc]init];
	for(Kdb3Group * group in root._subGroups){
		[stack push:group];
	}
	
	while(![stack isEmpty]){
		Kdb3Group * group = [stack pop];
		for(Kdb3Group * g in group._subGroups)
			[stack push:g];
		for(Kdb3Entry * e in group._metaEntries){
			[self writeEntry:e];
		}
	}
	
	[stack release];
}

-(void)persist{
	Kdb3Group * root = (Kdb3Group *)[_tree getRoot];
	[self persistGroups:root];
	[self persistEntries:root];
	[self persistMetaEntries:root];
	[_enc final];
}
@end
