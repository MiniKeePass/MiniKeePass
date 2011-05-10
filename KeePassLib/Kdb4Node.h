//
//  Kdb4Node.h
//  KeePass2
//
//  Created by Qiang Yu on 2/23/10.
//  Copyright 2010 Qiang Yu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Node.h"
#import "Kdb.h"
#import "Tree.h"

@interface Kdb4Group : Node<KdbGroup> {
	NSString * _uuid;
	uint32_t _image;
	NSString * _title;
	NSString * _comment;
	NSMutableArray * _subGroups;
	NSMutableArray * _entries;
}

@property(nonatomic, retain) NSString * _uuid;
@property(nonatomic, assign) uint32_t _image;
@property(nonatomic, retain, getter=getGroupName, setter=setGroupName) NSString * _title;
@property(nonatomic, retain) NSString * _comment;
@property(nonatomic, retain, getter=getSubGroups) NSMutableArray * _subGroups;
@property(nonatomic, retain, getter=getEntries) NSMutableArray * _entries;

@end


@interface Kdb4Entry: Node<KdbEntry>{
	NSString * _uuid;
	uint32_t _image;
	NSString * _title;
	NSString * _url;
	NSString * _username;
	NSString * _password;
	NSString * _comment;
	
	NSArray * _customeAttributeKeys;	
	NSMutableDictionary * _customeAttributes;
}

@property(nonatomic, retain) NSString * _uuid;
@property(nonatomic, assign) uint32_t _image;
@property(nonatomic, retain, getter=getEntryName, setter=setEntryName) NSString * _title;
@property(nonatomic, retain, getter=getUserName, setter=setUserName) NSString * _username;
@property(nonatomic, retain, getter=getPassword, setter=setPassword) NSString * _password;
@property(nonatomic, retain, getter=getComments, setter=setComments) NSString * _comment;
@property(nonatomic, retain, getter=getURL, setter=setURL) NSString * _url;
@property(nonatomic, retain) NSArray * _customeAttributeKeys;
@end


@interface Kdb4Tree:Tree<KdbTree>{
	NSMutableDictionary * _meta;
}

@property(nonatomic, retain) NSMutableDictionary * _meta;

-(NSString *)getMetaInfo:(NSString *)key;

@end