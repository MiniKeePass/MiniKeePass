//
//  KDB3Node.m
//  KeePass2
//
//  Created by Qiang Yu on 2/12/10.
//  Copyright 2010 Qiang Yu. All rights reserved.
//

#import "Kdb3Node.h"
#import "Kdb3Date.h"

@implementation Kdb3Group

@synthesize _parent;
@synthesize _id;
@synthesize _image;
@synthesize _title;
@synthesize _subGroups;
@synthesize _entries;
@synthesize _metaEntries;
@synthesize _creationTime;
@synthesize _lastModificationTime;
@synthesize _lastAccessTime;
@synthesize _expiryTime;

@synthesize _flags;

#pragma mark alloc/dealloc
-(void)dealloc{
    [_title release];
    [_parent release];
    [_subGroups release];
    [_metaEntries release];
    [_entries release];
    [super dealloc];
}

-(NSString *)description{
    NSString * descr = [NSString stringWithFormat:@"[id:%d title:%@]", _id, _title];
    return descr;
}

#pragma mark KdbGroup Protocol
-(void)addEntry:(id<KdbEntry>)child{
    Kdb3Entry * entry = (Kdb3Entry *)child;
    entry._parent = self;
    // meta node
    if([entry isMeta]){
        if(!_metaEntries)
            _metaEntries = [[NSMutableArray alloc] initWithCapacity:4];
        [_metaEntries addObject:child];
    }else{
        // normal node
        if(!_entries)
            _entries = [[NSMutableArray alloc] initWithCapacity:16];
        [_entries addObject:child];
    }
}

-(void)deleteEntry:(id<KdbEntry>)child{
    Kdb3Entry * entry = (Kdb3Entry *)child;
    entry._parent = nil;
    if([entry isMeta])
        [_metaEntries removeObject:child];
    else
        [_entries removeObject:child];
}

-(void)addSubGroup:(id<KdbGroup>)child{
    Kdb3Group * subGroup = (Kdb3Group *)child;
    if(!_subGroups)
        _subGroups = [[NSMutableArray alloc] initWithCapacity:8];
    subGroup._parent = self;
    [_subGroups addObject:subGroup];
}

-(void)deleteSubGroup:(id<KdbGroup>)child{
    Kdb3Group * subGroup = (Kdb3Group *)child;
    subGroup._parent = nil;
    [_subGroups removeObject:subGroup];
}

//
//break cyclic references to avoid memory leak
-(void)breakCyclcReference{
    self._parent = nil;
    for(Kdb3Group * group in _subGroups){
        [group breakCyclcReference];
    }

    for(Kdb3Entry * entry in _entries){
        [entry breakCyclcReference];
    }

    for(Kdb3Entry * entry in _metaEntries){
        [entry breakCyclcReference];
    }
}

@end


@implementation Kdb3Entry

@synthesize _parent;

@synthesize _uuid;
@synthesize _image;
@synthesize _title;
@synthesize _url;
@synthesize _username;
@synthesize _password;
@synthesize _comment;
@synthesize _creationTime;
@synthesize _lastModificationTime;
@synthesize _lastAccessTime;
@synthesize _expiryTime;

@synthesize _binaryDesc;
@synthesize _binarySize;
@synthesize _binary;

#pragma mark alloc/dealloc
-(id)initWithNewUUID{
    self = [super init];
    if(self) {
        _uuid = [[UUID alloc] init];
    }
    return self;
}

-(void)dealloc{
    [_uuid release];
    [_title release];
    [_url release];
    [_username release];
    [_password release];
    [_comment release];
    [_binaryDesc release];
    [_parent release];
    [_binary release];
    [super dealloc];
}

-(NSString *)description{
    NSString * descr = [NSString stringWithFormat:@"[UUID:%@ title:%@ \nusername:%@ \npassword:%@ \nurl:%@ \ncomment:%@ \nbinaryDesc:%@]", 
                        _uuid, _title, _username, _password, _url, _comment, _binaryDesc];
    return descr;
}

-(BOOL)isMeta{
    if(_binarySize==0) return NO;
    if(!_comment || ![_comment length]) return NO;
    if(!_binaryDesc || [_binaryDesc compare:@"bin-stream"]) return NO;
    if(!_title || [_title compare:@"Meta-Info"]) return NO;
    if(!_username || [_username compare:@"SYSTEM"]) return NO;
    if(!_url || [_url compare:@"$"]) return NO;
    if(_image) return NO;
    return YES;
}

//break cyclic references
-(void)breakCyclcReference{
    self._parent = nil;
}

@end

@implementation Kdb3Tree
@synthesize _root;

-(void)dealloc{
    [(Kdb3Group *)_root breakCyclcReference];
    [_root release];
    [super dealloc];
}

+(id<KdbTree>)newTree{
    ////
    
    id<KdbGroup> root = [[Kdb3Group alloc] init];
    [root setGroupName:@"%ROOT%"];
    
    Kdb3Group * group = [[Kdb3Group alloc] init];
    group._title = NSLocalizedString(@"Internet", @"Internet");

    [root addSubGroup:group];
    
    Kdb3Tree * tree = [[Kdb3Tree alloc] init];
    tree._root = root;
    
    [root release];
    [group release];
    
    return tree;
}

-(BOOL)isRecycleBin:(id<KdbGroup>)group{
    return [[group getGroupName] isEqualToString:@"Backup"];
}

@end



