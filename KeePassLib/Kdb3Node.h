//
//  KDB3Node.h
//  KeePass2
//
//  Created by Qiang Yu on 2/12/10.
//  Copyright 2010 Qiang Yu. All rights reserved.
//


/**
 * KDB3 GROUP and Node Definition
 **/
#import <Foundation/Foundation.h>
#import "Kdb.h"
#import "UUID.h"
#import "ByteBuffer.h"
#import "BinaryContainer.h"

////
//// Kdb3Group
////
@interface Kdb3Group : NSObject<KdbGroup>{
	uint32_t _id;
	uint32_t _image;
	NSString * _title;
	Kdb3Group * _parent;
	NSMutableArray * _subGroups;
	NSMutableArray * _metaEntries; //meta data 
	NSMutableArray * _entries;
	
	uint32_t _flags;
	uint8_t _creation[7];
	uint8_t _lastMod[7];
	uint8_t _lastAccess[7];
	uint8_t _expiry[7];	
}

@property(nonatomic, assign) uint32_t _id;
@property(nonatomic, assign) uint32_t _image;
@property(nonatomic, retain, getter=getGroupName, setter=setGroupName) NSString * _title;
@property(nonatomic, retain, getter=getParent, setter=setParent) Kdb3Group * _parent;
@property(nonatomic, readonly, getter=getSubGroups) NSArray * _subGroups; 
@property(nonatomic, readonly, getter=getEntries) NSArray * _entries;
@property(nonatomic, readonly)NSArray * _metaEntries;
@property(nonatomic, assign) uint32_t _flags;

-(uint8_t *)getCreation;
-(uint8_t *)getLastMod;
-(uint8_t *)getLastAccess;
-(uint8_t *)getExpiry;

-(void)setCreation:(NSDate *) date;
-(void)setLastMod:(NSDate *) date;
-(void)setLastAccess:(NSDate *) date;
-(void)setExpiry:(NSDate *) date;

//break cyclic references
-(void)breakCyclcReference;
@end


////
//// Kdb3Entry
////
@interface Kdb3Entry : NSObject<KdbEntry>{
	UUID * _uuid;

	uint32_t _image;
	NSString * _title;
	NSString * _url;
	NSString * _username;
	NSString * _password;
	NSString * _comment;
	Kdb3Group * _parent;

	uint8_t _creation[7];
	uint8_t _lastMod[7];
	uint8_t _lastAccess[7];
	uint8_t _expiry[7];

	NSString * _binaryDesc;
	uint32_t _binarySize;
	id<BinaryContainer> _binary;
}
@property(nonatomic, retain) UUID * _uuid;
@property(nonatomic, assign) uint32_t _image;
@property(nonatomic, assign) uint32_t _binarySize;
@property(nonatomic, retain, getter=getParent, setter=setParent) Kdb3Group * _parent;
@property(nonatomic, retain, getter=getEntryName, setter=setEntryName) NSString * _title;
@property(nonatomic, retain, getter=getUserName, setter=setUserName) NSString * _username;
@property(nonatomic, retain, getter=getPassword, setter=setPassword) NSString * _password;
@property(nonatomic, retain, getter=getComments, setter=setComments) NSString * _comment;
@property(nonatomic, retain) NSString * _binaryDesc;
@property(nonatomic, retain, getter=getURL, setter=setURL) NSString * _url;
@property(nonatomic, retain) id<BinaryContainer> _binary;

-(uint8_t *)getCreation;
-(uint8_t *)getLastMod;
-(uint8_t *)getLastAccess;
-(uint8_t *)getExpiry;

-(void)setCreation:(NSDate *) date;
-(void)setLastMod:(NSDate *) date;
-(void)setLastAccess:(NSDate *) date;
-(void)setExpiry:(NSDate *) date;

-(NSUInteger)getNumberOfCustomAttributes;
-(NSString *)getCustomAttributeName:(NSUInteger) index;
-(NSString *)getCustomAttributeValue:(NSUInteger) index;

-(BOOL)isMeta;
-(void)breakCyclcReference;

-(id)initWithNewUUID;

@end


@interface Kdb3Tree : NSObject<KdbTree>{
	id<KdbGroup> _root;
}
@property(nonatomic, retain, getter=getRoot, setter=setRoot) id<KdbGroup> _root;

//create a new Kdb3 tree
+(id<KdbTree>)newTree;

@end

