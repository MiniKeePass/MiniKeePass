//
//  Kdb3Parser.m
//  KeePass2
//
//  Created by Qiang Yu on 2/13/10.
//  Copyright 2010 Qiang Yu. All rights reserved.
//

#import "Kdb3Parser.h"
#import "Utils.h"
#import "Kdb3Node.h"
#import "Kdb3Date.h"

@interface Kdb3Parser(PrivateMethods)
-(void)read:(id<InputDataSource>)input toGroups:(NSMutableArray *)groups levels:(NSMutableArray *)levels numOfGroups:(uint32_t)numGroups;
-(void)read:(id<InputDataSource>)input toEntries:(NSMutableArray *)entries numOfEntries:(uint32_t)numEntries withGroups:(NSArray *)groups;
-(id<KdbTree>)buildTree:(NSArray *)groups levels:(NSArray *)levels entries:(NSArray *)entries;
@end

@implementation Kdb3Parser
-(id<KdbTree>)parse:(id<InputDataSource>)input numGroups:(uint32_t)numGroups numEntris:(uint32_t)numEntries{
	NSMutableArray * levels = [[NSMutableArray alloc]initWithCapacity:numGroups];
	NSMutableArray * groups = [[NSMutableArray alloc]initWithCapacity:numGroups];
	
	[self read:input toGroups:groups levels:levels numOfGroups:numGroups];	
	NSMutableArray * entries = [[NSMutableArray alloc]initWithCapacity:numEntries];	
	[self read:input toEntries:entries numOfEntries:numEntries withGroups:groups];
	
	id<KdbTree> rv = [self buildTree:groups levels:levels entries:entries];
	
	[groups release];
	[levels release];
	[entries release];
	
	return rv;
}

-(void)read:(id<InputDataSource>)input toGroups:(NSMutableArray *)groups levels:(NSMutableArray *)levels numOfGroups:(uint32_t)numGroups{
	uint16_t fieldType;
	uint32_t fieldSize;
	uint8_t dateBuffer[5];	
	
	//read groups
	for(uint32_t curGroup=0; curGroup<numGroups; curGroup++){
		Kdb3Group * group = [[Kdb3Group alloc] init];		
		do{

			fieldType = [Utils readInt16LE:input];		
			//DLog(@"fieldType %X", fieldType);
			fieldSize = [Utils readInt32LE:input];
			//DLog(@"fieldSize %X", fieldSize);			
			switch(fieldType){
				case 0x0000:{ [input moveReadOffset:fieldSize]; break; }
				case 0x0001:{ 
					group._id = [Utils readInt32LE:input];
					break;
				}
				case 0x0002: {
					ByteBuffer * buffer = [[ByteBuffer alloc]initWithSize:fieldSize dataSource:input];
					NSString * groupTitle = [[NSString alloc]initWithCString:(const char *)buffer._bytes encoding:NSUTF8StringEncoding];
					group._title = groupTitle;
					//DLog(@"grouptitle: 	%@", groupTitle);
					[groupTitle release];
					[buffer release];
					break;
				}
				case 0x0003: { 
					[input readBytes:dateBuffer length:fieldSize];
					[Kdb3Date date:[group getCreation] fromPacked:dateBuffer];
					//DLog(@"creation:%d-%d-%d %d:%d:%d", [entry getCreation][0]*100+[entry getCreation][1], [entry getCreation][2], [entry getCreation][3], 
					//						  [entry getCreation][4], [entry getCreation][5], [entry getCreation][6]);
					break;
				}
				case 0x0004: {  
					[input readBytes:dateBuffer length:fieldSize];
					[Kdb3Date date:[group getLastMod] fromPacked:dateBuffer];
					//DLog(@"creation:%d-%d-%d %d:%d:%d", [entry getCreation][0]*100+[entry getCreation][1], [entry getCreation][2], [entry getCreation][3], 
					//						  [entry getCreation][4], [entry getCreation][5], [entry getCreation][6]);
					break;
				}
				case 0x0005: { 
					[input readBytes:dateBuffer length:fieldSize];
					[Kdb3Date date:[group getLastAccess] fromPacked:dateBuffer];
					//DLog(@"creation:%d-%d-%d %d:%d:%d", [entry getCreation][0]*100+[entry getCreation][1], [entry getCreation][2], [entry getCreation][3], 
					//						  [entry getCreation][4], [entry getCreation][5], [entry getCreation][6]);
					break;
				}					
				case 0x0006: { 
					[input readBytes:dateBuffer length:fieldSize];
					[Kdb3Date date:[group getExpiry] fromPacked:dateBuffer];
					//DLog(@"creation:%d-%d-%d %d:%d:%d", [entry getCreation][0]*100+[entry getCreation][1], [entry getCreation][2], [entry getCreation][3], 
					//						  [entry getCreation][4], [entry getCreation][5], [entry getCreation][6]);
					break;
				}
				case 0x0007: {
					group._image = [Utils readInt32LE:input];
					break;
				}
				case 0x0008: {
					NSNumber * level = [NSNumber numberWithUnsignedInteger:[Utils readInt16LE:input]];
					[levels addObject:level];
					break;
				}
				case 0x0009: { 
					group._flags = [Utils readInt32LE:input];
					break;
				}
				case 0xFFFF: { [input moveReadOffset:fieldSize];break; }
				default:{
					//DLog(@"fieldType %X", fieldType);
					@throw [NSException exceptionWithName:@"ParseError" reason:@"ParseGroup" userInfo:nil];
				}
			}
			
			if(fieldType == 0xFFFF){
				[groups addObject:group];
				break;
			}
		}while(true);
		[group release];
	}
}

-(void)read:(id<InputDataSource>)input toEntries:(NSMutableArray *)entries numOfEntries:(uint32_t)numEntries withGroups:(NSArray *)groups {
	uint16_t fieldType;
	uint32_t fieldSize;
	uint8_t dateBuffer[5];
	
	for(uint32_t curEntry=0; curEntry<numEntries; curEntry++){
		Kdb3Entry * entry = [[Kdb3Entry alloc]init];
		uint32_t groupId;
		do{
			fieldType = [Utils readInt16LE:input];		
			fieldSize = [Utils readInt32LE:input];
					
			switch(fieldType){
				case 0x0000: { [input moveReadOffset:fieldSize];break; }
				case 0x0001: { 
					UUID * uuid = [[UUID alloc]initWithSize:fieldSize dataSource:input]; 
					entry._uuid = uuid;
					//DLog(@"uuid: %@", uuid);
					[uuid release];
					break; 
				}
				case 0x0002: {
					groupId = [Utils readInt32LE:input];
					/*for(Kdb3Group * g in groups){
						//find the father
						if(g._id == groupId){
							[g addEntry:entry];
							//DLog(@"found parent:%@", g);
							break;
						}
					}*/
					break;  
				}
				case 0x0003:{
					entry._image = [Utils readInt32LE:input]; 
					break;
				}
				case 0x0004: {
					ByteBuffer * buffer = [[ByteBuffer alloc]initWithSize:fieldSize dataSource:input];
					NSString * title = [[NSString alloc]initWithCString:(const char *)buffer._bytes encoding:NSUTF8StringEncoding];
					entry._title = title;
					//DLog(@"title: %@", title);
					[title release];
					[buffer release];
					break;
				}
				case 0x0005: {
					ByteBuffer * buffer = [[ByteBuffer alloc]initWithSize:fieldSize dataSource:input];
					NSString * url = [[NSString alloc]initWithCString:(const char *)buffer._bytes encoding:NSUTF8StringEncoding];
					entry._url = url;
					//DLog(@"url: %@", url);
					[url release];
					[buffer release];
					break;
				}
				case 0x0006: {
					ByteBuffer * buffer = [[ByteBuffer alloc]initWithSize:fieldSize dataSource:input];
					NSString * username = [[NSString alloc]initWithCString:(const char *)buffer._bytes encoding:NSUTF8StringEncoding];
					entry._username = username;
					//DLog(@"username: %@", username);				
					[username release];
					[buffer release];
					break;
				}
				case 0x0007:{
					ByteBuffer * buffer = [[ByteBuffer alloc]initWithSize:fieldSize dataSource:input];
					NSString * password = [[NSString alloc]initWithCString:(const char *)buffer._bytes encoding:NSUTF8StringEncoding];
					entry._password = password;
					//DLog(@"password: %@", password);				
					[password release];
					[buffer release];
					break;
				}
				case 0x0008:{
					ByteBuffer * buffer = [[ByteBuffer alloc]initWithSize:fieldSize dataSource:input];
					NSString * comment = [[NSString alloc]initWithCString:(const char *)buffer._bytes encoding:NSUTF8StringEncoding];
					entry._comment = comment;
					//DLog(@"comment: %@", comment);				
					[comment release];
					[buffer release];
					break;
				}
				case 0x0009:{
					[input readBytes:dateBuffer length:fieldSize];
					[Kdb3Date date:[entry getCreation] fromPacked:dateBuffer];
					//DLog(@"creation:%d-%d-%d %d:%d:%d", [entry getCreation][0]*100+[entry getCreation][1], [entry getCreation][2], [entry getCreation][3], 
					//						  [entry getCreation][4], [entry getCreation][5], [entry getCreation][6]);
					break;
				}
				case 0x000A:{
					[input readBytes:dateBuffer length:fieldSize];
					[Kdb3Date date:[entry getLastMod] fromPacked:dateBuffer];
					//DLog(@"lastMod:%d-%d-%d %d:%d:%d", [entry getLastMod][0]*100+[entry getLastMod][1], [entry getLastMod][2], [entry getLastMod][3], 
					//	 [entry getLastMod][4], [entry getLastMod][5], [entry getLastMod][6]);					
					break;
				}
				case 0x000B:{
					[input readBytes:dateBuffer length:fieldSize];
					[Kdb3Date date:[entry getLastAccess] fromPacked:dateBuffer];
					//DLog(@"lastAccess:%d-%d-%d %d:%d:%d", [entry getLastAccess][0]*100+[entry getLastAccess][1], [entry getLastAccess][2], [entry getLastAccess][3], 
					//	 [entry getLastAccess][4], [entry getLastAccess][5], [entry getLastAccess][6]);					
					break;
				}
				case 0x000C:{
					[input readBytes:dateBuffer length:fieldSize];
					[Kdb3Date date:[entry getExpiry] fromPacked:dateBuffer];
					//DLog(@"expiry:%d-%d-%d %d:%d:%d", [entry getExpiry][0]*100+[entry getExpiry][1], [entry getExpiry][2], [entry getExpiry][3], 
					//	 [entry getCreation][4], [entry getExpiry][5], [entry getExpiry][6]);					
					break;
				}
				case 0x000D:{
					ByteBuffer * buffer = [[ByteBuffer alloc]initWithSize:fieldSize dataSource:input];
					NSString * binaryDesc = [[NSString alloc]initWithCString:(const char *)buffer._bytes encoding:NSUTF8StringEncoding];
					entry._binaryDesc = binaryDesc;
					//DLog(@"binaryDesc %@", binaryDesc);
					[binaryDesc release];
					[buffer release];
					break;	
				}
				case 0x000E:
					entry._binarySize = fieldSize;
					if(fieldSize){
						MemoryBinaryContainer * container = [[MemoryBinaryContainer alloc]init];
						[container storeBinary:input size:fieldSize];
						entry._binary = container;
						[container release];
					}
					break;
				case 0xFFFF:{
					[input moveReadOffset:fieldSize];
					//all fields of the entry have been retrieved,
					//find the parent.
					for(Kdb3Group * g in groups){
						//find the father
						if(g._id == groupId){
							[g addEntry:entry];
							break;
						}
					 }										
					break;
				}
				default:
					@throw [NSException exceptionWithName:@"ParseError" reason:@"ParseEntry" userInfo:nil];
			}
			
			if(fieldType == 0xFFFF){
				[entries addObject:entry];
				break;
			}
		}while(true);
		[entry release];
	}
}

-(id<KdbTree>)buildTree:(NSArray *)groups levels:(NSArray *)levels entries:(NSArray *)entries{
	///
	uint32_t level = [[levels objectAtIndex:0]unsignedIntValue];
	if(level!=0) @throw [NSException exceptionWithName:@"InvalidData" reason:@"InvalidTree" userInfo:nil];
	
	id<KdbTree> tree = [[Kdb3Tree alloc]init];
	
	Kdb3Group * rootGroup = [[Kdb3Group alloc] init];	

	rootGroup._title = @"$ROOT$";
	rootGroup._parent = nil;
	((Kdb3Tree *)tree)._root = rootGroup;
	[rootGroup release];
	
	//find the parent for every group
	for(int i=0; i<[groups count]; i++){
		Kdb3Group * group = [groups objectAtIndex:i];
		level = [[levels objectAtIndex:i]unsignedIntValue];		
		
		if(level==0){
			[rootGroup addSubGroup:group];
			continue;
		}
		
		uint32_t level2;
		int j;
		
		//the first item with a lower level is the parent
		for(j=i-1; j>=0; j--){
			level2 = [[levels objectAtIndex:j]unsignedIntValue];
			if(level2<level){
				if(level-level2!=1) 
					@throw [NSException exceptionWithName:@"InvalidData" reason:@"InvalidTree" userInfo:nil];
				else
					break;
			}
			if(j==0)
				@throw [NSException exceptionWithName:@"InvalidData" reason:@"InvalidTree" userInfo:nil];
		}
		
		Kdb3Group * parent = [groups objectAtIndex:j];
		[parent addSubGroup:group];
	}
	
	return [tree autorelease];
}

@end
