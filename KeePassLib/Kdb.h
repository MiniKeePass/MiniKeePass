//
//  KDB.h
//  KeePass2
//
//  Created by Qiang Yu on 1/1/10.
//  Copyright 2010 Qiang Yu. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol KdbEntry;

@protocol KdbGroup<NSObject>
-(id<KdbGroup>)getParent;
-(void)setParent:(id<KdbGroup>)parent;

-(NSString*)getGroupName;
-(void)setGroupName:(NSString *)groupName;

-(NSArray *)getEntries;
-(void)addEntry:(id<KdbEntry>)child;
-(void)deleteEntry:(id<KdbEntry>)child;

-(NSArray *)getSubGroups;
-(void)addSubGroup:(id<KdbGroup>)child;
-(void)deleteSubGroup:(id<KdbGroup>)child;

-(void)setCreation:(NSDate *) date;
-(void)setLastMod:(NSDate *) date;
-(void)setLastAccess:(NSDate *) date;
-(void)setExpiry:(NSDate *) date;

@end

@protocol KdbEntry<NSObject>
-(id<KdbGroup>)getParent;
-(void)setParent:(id<KdbGroup>)parent;

-(NSString*)getEntryName;
-(void)setEntryName:(NSString *)entryName;

-(NSString*)getUserName;
-(void)setUserName:(NSString *)userName;

-(NSString*)getPassword;
-(void)setPassword:(NSString *)password;

-(NSString*)getURL;
-(void)setURL:(NSString *)url;

-(NSString*)getComments;
-(void)setComments:(NSString *)comments;

-(NSUInteger)getNumberOfCustomAttributes;
-(NSString *)getCustomAttributeName:(NSUInteger) index;
-(NSString *)getCustomAttributeValue:(NSUInteger) index;

-(void)setCreation:(NSDate *) date;
-(void)setLastMod:(NSDate *) date;
-(void)setLastAccess:(NSDate *) date;
-(void)setExpiry:(NSDate *) date;

/* TODO: 
-(NSDate*)getCreationDate;
-(NSDate*)getLastAccessDate;
-(NSDate*)getModificationDate;
-(NSDate*)getExpiry;

-(void)setCreationDateYear:(int)yyyy month:(int)mm day:(int)dd hour:(int)hh minutes:(int)mi seconds:(int)ss;
-(void)setLastAccessDate:(int)yyyy month:(int)mm day:(int)dd hour:(int)hh minutes:(int)mi seconds:(int)ss;
-(void)setModificationDate:(int)yyyy month:(int)mm day:(int)dd hour:(int)hh minutes:(int)mi seconds:(int)ss;
-(void)setExpiry:(int)yyyy month:(int)mm day:(int)dd hour:(int)hh minutes:(int)mi seconds:(int)ss;
*/

@end

@protocol KdbTree<NSObject>
-(id<KdbGroup>)getRoot;
-(BOOL)isRecycleBin:(id<KdbGroup>)group;
@end