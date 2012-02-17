//
//  Kdb3Persist.m
//  KeePass2
//
//  Created by Qiang Yu on 2/22/10.
//  Copyright 2010 Qiang Yu. All rights reserved.
//

#import "Kdb3Persist.h"
#import "Utils.h"
#import "Kdb3Date.h"

@interface Kdb3Persist(PrivateMethods)
- (void)persistGroups:(Kdb3Group*)root;
- (void)persistEntries:(Kdb3Group*)root;
- (void)persistMetaEntries:(Kdb3Group*)root;
- (void)writeGroup:(Kdb3Group*)group;
- (void)writeEntry:(Kdb3Entry*)entry;
- (void)appendField:(uint16_t)type size:(uint32_t)size bytes:(const void*)value;
@end

@implementation Kdb3Persist

- (id)initWithTree:(Kdb3Tree*)t andOutputStream:(OutputStream*)stream {
    self = [super init];
    if (self) {
        tree = [t retain];
        outputStream = [stream retain];
    }
    return self;
}

- (void)dealloc {
    [tree release];
    [outputStream release];
    [super dealloc];
}

- (void)persist {
    Kdb3Group *root = (Kdb3Group*)tree.root;
    [self persistGroups:root];
    [self persistEntries:root];
    [self persistMetaEntries:root];
}

- (void)persistGroups:(Kdb3Group*)root {
    for (Kdb3Group *group in root.groups) {
        [self writeGroup:group];
        [self persistGroups:group];
    }
}

- (void)persistEntries:(Kdb3Group*)root {
    for (Kdb3Entry *entry in root.entries) {
        [self writeEntry:entry];
    }
    
    for (Kdb3Group *group in root.groups) {
        [self persistEntries:group];
    }
}

- (void)persistMetaEntries:(Kdb3Group*)root {
    for (Kdb3Entry *entry in root.metaEntries) {
        [self writeEntry:entry];
    }
    
    for (Kdb3Group *group in root.groups) {
        [self persistMetaEntries:group];
    }
}

- (void)writeGroup:(Kdb3Group*)group {
    uint8_t packedDate[5];
    uint32_t tmp32;
    
    tmp32 = CFSwapInt32HostToLittle(group.groupId);
    [self appendField:1 size:4 bytes:&tmp32];
    
    if(![Utils emptyString:group.name]){
        const char * title = [group.name cStringUsingEncoding:NSUTF8StringEncoding];
        [self appendField:2 size:strlen(title)+1 bytes:(void *)title];
    }
    
    [Kdb3Date toPacked:group.creationTime bytes:packedDate];
    [self appendField:3 size:5 bytes:packedDate];
    
    [Kdb3Date toPacked:group.lastModificationTime bytes:packedDate];
    [self appendField:3 size:5 bytes:packedDate];
    
    [Kdb3Date toPacked:group.lastAccessTime bytes:packedDate];
    [self appendField:3 size:5 bytes:packedDate];
    
    [Kdb3Date toPacked:group.expiryTime bytes:packedDate];
    [self appendField:3 size:5 bytes:packedDate];
    
    tmp32 = CFSwapInt32HostToLittle(group.image);
    [self appendField:7 size:4 bytes:&tmp32];
    
    // Get the level of the group
    uint16_t level = -1;
    for (KdbGroup *g = group; g.parent != nil; g = g.parent) {
        level++;
    }
    
    level = CFSwapInt16HostToLittle(level);
    [self appendField:8 size:2 bytes:&level];
    
    tmp32 = CFSwapInt32HostToLittle(group.flags);
    [self appendField:9 size:4 bytes:&tmp32];
    
    // End of the group
    [self appendField:0xFFFF size:0 bytes:nil];
}

- (void)writeEntry:(Kdb3Entry*)entry {
    uint8_t buffer[16];
    uint32_t tmp32;
    const char *tmpStr;
    
    [entry.uuid getBytes:buffer length:16];
    [self appendField:1 size:16 bytes:buffer];
    
    tmp32 = CFSwapInt32HostToLittle(((Kdb3Group*)entry.parent).groupId);
    [self appendField:2 size:4 bytes:&tmp32];
    
    tmp32 = CFSwapInt32HostToLittle(entry.image);
    [self appendField:3 size:4 bytes:&tmp32];
    
    tmpStr = "";
    if (![Utils emptyString:entry.title]) {
        tmpStr = [entry.title cStringUsingEncoding:NSUTF8StringEncoding];
    }
    [self appendField:4 size:strlen(tmpStr) + 1 bytes:tmpStr];
    
    tmpStr = "";
    if (![Utils emptyString:entry.url]) {
        tmpStr = [entry.url cStringUsingEncoding:NSUTF8StringEncoding];
    }
    [self appendField:5 size:strlen(tmpStr) + 1 bytes:tmpStr];
    
    tmpStr = "";
    if (![Utils emptyString:entry.username]) {
        tmpStr = [entry.username cStringUsingEncoding:NSUTF8StringEncoding];
    }
    [self appendField:6 size:strlen(tmpStr) + 1 bytes:tmpStr];
    
    tmpStr = "";
    if (![Utils emptyString:entry.password]) {
        tmpStr = [entry.password cStringUsingEncoding:NSUTF8StringEncoding];
    }
    [self appendField:7 size:strlen(tmpStr) + 1 bytes:tmpStr];
    
    tmpStr = "";
    if (![Utils emptyString:entry.notes]) {
        tmpStr = [entry.notes cStringUsingEncoding:NSUTF8StringEncoding];
    }
    [self appendField:8 size:strlen(tmpStr) + 1 bytes:tmpStr];
    
    [Kdb3Date toPacked:entry.creationTime bytes:buffer];
    [self appendField:9 size:5 bytes:buffer];
    
    [Kdb3Date toPacked:entry.lastModificationTime bytes:buffer];
    [self appendField:10 size:5 bytes:buffer];
    
    [Kdb3Date toPacked:entry.lastAccessTime bytes:buffer];
    [self appendField:11 size:5 bytes:buffer];
    
    [Kdb3Date toPacked:entry.expiryTime bytes:buffer];
    [self appendField:12 size:5 bytes:buffer];
    
    tmpStr = "";
    if (![Utils emptyString:entry.binaryDesc]) {
        tmpStr = [entry.binaryDesc cStringUsingEncoding:NSUTF8StringEncoding];
    }
    [self appendField:13 size:strlen(tmpStr)+1 bytes:tmpStr];
    
    if (entry.binary && entry.binary.length) {
        [self appendField:14 size:entry.binary.length bytes:entry.binary.bytes];
    } else {
        [self appendField:14 size:0 bytes:nil];
    }
    
    [self appendField:0xFFFF size:0 bytes:nil];
}

- (void)appendField:(uint16_t)type size:(uint32_t)size bytes:(const void*)buffer {
    [outputStream writeInt16:CFSwapInt16HostToLittle(type)];
    [outputStream writeInt32:CFSwapInt32HostToLittle(size)];
    if (size > 0) {
        [outputStream write:buffer length:size];
    }
}


@end
