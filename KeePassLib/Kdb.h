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
    KdbGroup *__unsafe_unretained parent;

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

@property(nonatomic, unsafe_unretained) KdbGroup *parent;

@property(nonatomic, assign) NSInteger image;
@property(nonatomic, copy) NSString *name;
@property(nonatomic, readonly) NSArray *groups;
@property(nonatomic, readonly) NSArray *entries;

@property(nonatomic, strong) NSDate *creationTime;
@property(nonatomic, strong) NSDate *lastModificationTime;
@property(nonatomic, strong) NSDate *lastAccessTime;
@property(nonatomic, strong) NSDate *expiryTime;

@property(nonatomic, assign) BOOL canAddEntries;

- (void)addGroup:(KdbGroup *)group;
- (void)deleteGroup:(KdbGroup *)group;
- (void)moveGroup:(KdbGroup *)group toGroup:(KdbGroup *)toGroup;

- (void)addEntry:(KdbEntry *)entry;
- (void)deleteEntry:(KdbEntry *)entry;
- (void)moveEntry:(KdbEntry *)entry toGroup:(KdbGroup *)toGroup;

- (BOOL)containsGroup:(KdbGroup*)group;

@end

@interface KdbEntry : NSObject {
    KdbGroup *__unsafe_unretained parent;

    NSInteger image;

    NSDate *creationTime;
    NSDate *lastModificationTime;
    NSDate *lastAccessTime;
    NSDate *expiryTime;
}

@property(nonatomic, unsafe_unretained) KdbGroup *parent;

@property(nonatomic, assign) NSInteger image;

- (NSString *)title;
- (void)setTitle:(NSString *)title;

- (NSString *)username;
- (void)setUsername:(NSString *)username;

- (NSString *)password;
- (void)setPassword:(NSString *)password;

- (NSString *)url;
- (void)setUrl:(NSString *)url;

- (NSString *)notes;
- (void)setNotes:(NSString *)notes;

- (BOOL)hasChanged:(KdbEntry *)entry;
- (KdbEntry *)deepCopy;

@property(nonatomic, strong) NSDate *creationTime;
@property(nonatomic, strong) NSDate *lastModificationTime;
@property(nonatomic, strong) NSDate *lastAccessTime;
@property(nonatomic, strong) NSDate *expiryTime;

@end

@interface KdbTree : NSObject {
    KdbGroup *root;
}

@property(nonatomic, strong) KdbGroup *root;

- (KdbGroup*)createGroup:(KdbGroup *)parent;
- (void)removeGroup:(KdbGroup *)group; // Uses recycle bin with Keepass 2.x files

- (KdbEntry*)createEntry:(KdbGroup *)parent;
- (void)removeEntry:(KdbEntry *)entry; // Uses recycle bin with Keepass 2.x files
- (void)createEntryBackup:(KdbEntry *)entry backupEntry:(KdbEntry *)backupEntry; // Uses entry history with Keepass 2.x files

@end
