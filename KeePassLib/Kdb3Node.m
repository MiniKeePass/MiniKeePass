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
@synthesize flags;
@synthesize metaEntries;

- (id)init {
    self = [super init];
    if (self) {
        metaEntries = [[NSMutableArray alloc] initWithCapacity:4];
    }
    return self;
}

- (void)dealloc {
    [metaEntries release];
    [super dealloc];
}

- (void)addEntry:(KdbEntry*)entry {
    entry.parent = self;
    
    if ([(Kdb3Entry*)entry isMeta]) {
        [metaEntries addObject:entry];
    } else {
        [entries addObject:entry];
    }
}

- (void)deleteEntry:(KdbEntry*)entry {
    entry.parent = nil;
    
    if ([(Kdb3Entry*)entry isMeta]) {
        [metaEntries removeObject:entry];
    } else {
        [entries removeObject:entry];
    }
}

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
    if(_binarySize==0) return NO;
    if(!notes || ![notes length]) return NO;
    if(!_binaryDesc || [_binaryDesc compare:@"bin-stream"]) return NO;
    if(!title || [title compare:@"Meta-Info"]) return NO;
    if(!username || [username compare:@"SYSTEM"]) return NO;
    if(!url || [url compare:@"$"]) return NO;
    if(image) return NO;
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
