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

- (id)init {
    self = [super init];
    if (self) {
        _metaEntries = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)addEntry:(KdbEntry *)entry {
    entry.parent = self;
    
    if ([(Kdb3Entry *)entry isMeta]) {
        [_metaEntries addObject:entry];
    } else {
        [entries addObject:entry];
    }
}

- (void)removeEntry:(KdbEntry *)entry {
    entry.parent = nil;
    
    if ([(Kdb3Entry *)entry isMeta]) {
        [_metaEntries removeObject:entry];
    } else {
        [entries removeObject:entry];
    }
}

@end


@implementation Kdb3Entry

- (BOOL)isMeta {
    if (!_binary || _binary.length == 0) {
        return NO;
    }
    if (!_notes || ![_notes length]) {
        return NO;
    }
    if (!_binaryDesc || [_binaryDesc compare:@"bin-stream"]) {
        return NO;
    }
    if (!_title || [_title compare:@"Meta-Info"]) {
        return NO;
    }
    if (!_username || [_username compare:@"SYSTEM"]) {
        return NO;
    }
    if (!_url || [_url compare:@"$"]) {
        return NO;
    }
    if (image) {
        return NO;
    }
    return YES;
}

@end


@implementation Kdb3Tree

- (id)init {
    self = [super init];
    if (self) {
        _rounds = DEFAULT_TRANSFORMATION_ROUNDS;
    }
    return self;
}

- (BOOL)isGroupIdUnique:(Kdb3Group*)group groupId:(uint32_t)groupId {
    if (group.groupId == groupId) {
        return NO;
    }
    
    for (Kdb3Group *g in group.groups) {
        if (![self isGroupIdUnique:g groupId:groupId]) {
            return NO;
        }
    }
    
    return YES;
}

- (KdbGroup*)createGroup:(KdbGroup*)parent {
    Kdb3Group *group = [[Kdb3Group alloc] init];
    
    do {
        group.groupId = (uint32_t)random();
    } while (![self isGroupIdUnique:(Kdb3Group*)root groupId:group.groupId]);

    return group;
}

- (KdbEntry*)createEntry:(KdbGroup*)parent {
    Kdb3Entry *entry = [[Kdb3Entry alloc] init];
    entry.uuid = [UUID uuid];

    return entry;
}

@end
