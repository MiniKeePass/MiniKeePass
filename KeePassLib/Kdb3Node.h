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
@interface Kdb3Group : NSObject<KdbGroup> {
    Kdb3Group *_parent;
    
    uint32_t _id;
    NSInteger _image;
    NSString *_title;
    NSMutableArray *_subGroups;
    NSMutableArray *_entries;
    NSMutableArray *_metaEntries;
    
    NSDate *_creationTime;
    NSDate *_lastModificationTime;
    NSDate *_lastAccessTime;
    NSDate *_expiryTime;
    
    uint32_t _flags;
}

@property(nonatomic, retain, getter=getParent, setter=setParent:) Kdb3Group *_parent;

@property(nonatomic, assign) uint32_t _id;
@property(nonatomic, assign, getter=getImage, setter=setImage:) NSInteger _image;
@property(nonatomic, retain, getter=getGroupName, setter=setGroupName:) NSString *_title;
@property(nonatomic, readonly, getter=getSubGroups) NSArray *_subGroups; 
@property(nonatomic, readonly, getter=getEntries) NSArray *_entries;
@property(nonatomic, readonly) NSArray *_metaEntries;

@property(nonatomic, retain, getter=getCreationTime, setter=setCreationTime:) NSDate *_creationTime;
@property(nonatomic, retain, getter=getLastModificationTime, setter=setLastModificationTime:) NSDate *_lastModificationTime;
@property(nonatomic, retain, getter=getLastAccessTime, setter=setLastAccessTime:) NSDate *_lastAccessTime;
@property(nonatomic, retain, getter=getExpiryTime, setter=setExpiryTime:) NSDate *_expiryTime;

@property(nonatomic, assign) uint32_t _flags;

//break cyclic references
-(void)breakCyclcReference;
@end


////
//// Kdb3Entry
////
@interface Kdb3Entry : NSObject<KdbEntry> {
    Kdb3Group *_parent;

    UUID *_uuid;
    NSInteger _image;
    NSString *_title;
    NSString *_username;
    NSString *_password;
    NSString *_url;
    NSString *_comment;
    
    NSDate *_creationTime;
    NSDate *_lastModificationTime;
    NSDate *_lastAccessTime;
    NSDate *_expiryTime;
    
    NSString *_binaryDesc;
    uint32_t _binarySize;
    id<BinaryContainer> _binary;
}

@property(nonatomic, retain, getter=getParent, setter=setParent:) Kdb3Group *_parent;

@property(nonatomic, retain) UUID *_uuid;
@property(nonatomic, assign, getter=getImage, setter=setImage:) NSInteger _image;
@property(nonatomic, retain, getter=getEntryName, setter=setEntryName:) NSString *_title;
@property(nonatomic, retain, getter=getUserName, setter=setUserName:) NSString *_username;
@property(nonatomic, retain, getter=getPassword, setter=setPassword:) NSString *_password;
@property(nonatomic, retain, getter=getURL, setter=setURL:) NSString *_url;
@property(nonatomic, retain, getter=getComments, setter=setComments:) NSString *_comment;

@property(nonatomic, retain, getter=getCreationTime, setter=setCreationTime:) NSDate *_creationTime;
@property(nonatomic, retain, getter=getLastModificationTime, setter=setLastModificationTime:) NSDate *_lastModificationTime;
@property(nonatomic, retain, getter=getLastAccessTime, setter=setLastAccessTime:) NSDate *_lastAccessTime;
@property(nonatomic, retain, getter=getExpiryTime, setter=setExpiryTime:) NSDate *_expiryTime;

@property(nonatomic, retain) NSString *_binaryDesc;
@property(nonatomic, assign) uint32_t _binarySize;
@property(nonatomic, retain) id<BinaryContainer> _binary;

-(BOOL)isMeta;
-(void)breakCyclcReference;

-(id)initWithNewUUID;

@end


@interface Kdb3Tree : NSObject<KdbTree> {
    id<KdbGroup> _root;
}
@property(nonatomic, retain, getter=getRoot, setter=setRoot:) id<KdbGroup> _root;

//create a new Kdb3 tree
+(id<KdbTree>)newTree;

@end

