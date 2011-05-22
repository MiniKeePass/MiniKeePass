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

@synthesize _id;
@synthesize _flags;
@synthesize _metaEntries;

- (void)dealloc {
    [_metaEntries release];
    [super dealloc];
}

/*
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
*/

@end


@implementation Kdb3Entry

@synthesize _uuid;
@synthesize _binaryDesc;
@synthesize _binarySize;
@synthesize _binary;

- (id)initWithNewUUID {
    self = [super init];
    if (self) {
        _uuid = [[UUID alloc] init];
    }
    return self;
}

- (void)dealloc {
    [_uuid release];
    [_binaryDesc release];
    [_binary release];
    [super dealloc];
}

-(BOOL)isMeta{
    /*
    if(_binarySize==0) return NO;
    if(!_comment || ![_comment length]) return NO;
    if(!_binaryDesc || [_binaryDesc compare:@"bin-stream"]) return NO;
    if(!_title || [_title compare:@"Meta-Info"]) return NO;
    if(!_username || [_username compare:@"SYSTEM"]) return NO;
    if(!_url || [_url compare:@"$"]) return NO;
    if(_image) return NO;
     */
    return YES;
}

@end


@implementation Kdb3Tree

- (id)initNewTree {
    self = [super init];
    if (self) {
        root = [[Kdb3Group alloc] init];
        root.name = @"%ROOT%";
        
        Kdb3Group *group = [[Kdb3Group alloc] init];
        group.name = NSLocalizedString(@"Internet", @"Internet");
        [root addGroup:group];
        [group release];
    }
    return self;
}

@end
