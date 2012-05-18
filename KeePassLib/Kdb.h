//
//  KDB.h
//  KeePass2
//
//  Created by Qiang Yu on 1/1/10.
//  Copyright 2010 Qiang Yu. All rights reserved.
//

#import <Foundation/Foundation.h>

#define DEFAULT_TRANSFORMATION_ROUNDS 6000

@class KdbEntry;

@interface KdbGroup : NSObject {
    KdbGroup *parent;
    
    NSInteger image;
    NSString *name;
    NSMutableArray *groups;
    NSMutableArray *entries;
    
    NSDate *creationTime;
    NSDate *lastModificationTime;
    NSDate *lastAccessTime;
    NSDate *expiryTime;
    
    BOOL canAddEntries;
}

@property(nonatomic, assign) KdbGroup *parent;

@property(nonatomic, assign) NSInteger image;
@property(nonatomic, copy) NSString *name;
@property(nonatomic, readonly) NSArray *groups; 
@property(nonatomic, readonly) NSArray *entries;

@property(nonatomic, retain) NSDate *creationTime;
@property(nonatomic, retain) NSDate *lastModificationTime;
@property(nonatomic, retain) NSDate *lastAccessTime;
@property(nonatomic, retain) NSDate *expiryTime;

@property(nonatomic, assign) BOOL canAddEntries;

- (void)addGroup:(KdbGroup*)group;
- (void)removeGroup:(KdbGroup*)group;

- (void)addEntry:(KdbEntry*)entry;
- (void)removeEntry:(KdbEntry*)entry;

@end

@interface KdbEntry : NSObject {
    KdbGroup *parent;
    
    NSInteger image;
    NSString *title;
    NSString *username;
    NSString *password;
    NSString *url;
    NSString *notes;
    
    NSDate *creationTime;
    NSDate *lastModificationTime;
    NSDate *lastAccessTime;
    NSDate *expiryTime;
}

@property(nonatomic, assign) KdbGroup *parent;

@property(nonatomic, assign) NSInteger image;
@property(nonatomic, copy) NSString *title;
@property(nonatomic, copy) NSString *username;
@property(nonatomic, copy) NSString *password;
@property(nonatomic, copy) NSString *url;
@property(nonatomic, copy) NSString *notes;

@property(nonatomic, retain) NSDate *creationTime;
@property(nonatomic, retain) NSDate *lastModificationTime;
@property(nonatomic, retain) NSDate *lastAccessTime;
@property(nonatomic, retain) NSDate *expiryTime;

@end

@interface KdbTree : NSObject {
    KdbGroup *root;
}

@property(nonatomic, retain) KdbGroup *root;

- (KdbGroup*)createGroup:(KdbGroup*)parent;
- (KdbEntry*)createEntry:(KdbGroup*)parent;

@end
