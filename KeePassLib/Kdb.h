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
- (id<KdbGroup>)getParent;
- (void)setParent:(id<KdbGroup>)parent;

- (NSUInteger)getImage;
- (void)setImage:(NSUInteger)image;

- (NSString*)getGroupName;
- (void)setGroupName:(NSString*)groupName;

- (NSArray*)getEntries;
- (void)addEntry:(id<KdbEntry>)child;
- (void)deleteEntry:(id<KdbEntry>)child;

- (NSArray*)getSubGroups;
- (void)addSubGroup:(id<KdbGroup>)child;
- (void)deleteSubGroup:(id<KdbGroup>)child;

- (NSDate*)getCreationTime;
- (void)setCreationTime:(NSDate*)date;

- (NSDate*)getLastModificationTime;
- (void)setLastModificationTime:(NSDate*)date;

- (NSDate*)getLastAccessTime;
- (void)setLastAccessTime:(NSDate*)date;

- (NSDate*)getExpiryTime;
- (void)setExpiryTime:(NSDate*)date;

@end

@protocol KdbEntry<NSObject>
- (id<KdbGroup>)getParent;
- (void)setParent:(id<KdbGroup>)parent;

- (NSUInteger)getImage;
- (void)setImage:(NSUInteger)image;

- (NSString*)getEntryName;
- (void)setEntryName:(NSString*)entryName;

- (NSString*)getUserName;
- (void)setUserName:(NSString*)userName;

- (NSString*)getPassword;
- (void)setPassword:(NSString*)password;

- (NSString*)getURL;
- (void)setURL:(NSString*)url;

- (NSString*)getComments;
- (void)setComments:(NSString*)comments;

- (NSDate*)getCreationTime;
- (void)setCreationTime:(NSDate*)date;

- (NSDate*)getLastModificationTime;
- (void)setLastModificationTime:(NSDate*)date;

- (NSDate*)getLastAccessTime;
- (void)setLastAccessTime:(NSDate*)date;

- (NSDate*)getExpiryTime;
- (void)setExpiryTime:(NSDate*)date;

@end

@protocol KdbTree<NSObject>
-(id<KdbGroup>)getRoot;
-(BOOL)isRecycleBin:(id<KdbGroup>)group;
@end
