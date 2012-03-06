//
//  Kdb3Parser.m
//  KeePass2
//
//  Created by Qiang Yu on 2/13/10.
//  Copyright 2010 Qiang Yu. All rights reserved.
//

#import "Kdb3Parser.h"
#import "Kdb3Node.h"
#import "Kdb3Date.h"

@interface Kdb3Parser(PrivateMethods)
- (void)read:(InputStream*)inputStream toGroups:(NSMutableArray*)groups levels:(NSMutableArray*)levels numOfGroups:(uint32_t)numGroups;
- (void)read:(InputStream*)inputStream toEntries:(NSMutableArray*)entries numOfEntries:(uint32_t)numEntries withGroups:(NSArray*)groups;
- (Kdb3Tree*)buildTree:(NSArray*)groups levels:(NSArray*)levels entries:(NSArray*)entries;
@end

@implementation Kdb3Parser

- (Kdb3Tree*)parse:(InputStream*)inputStream numGroups:(uint32_t)numGroups numEntris:(uint32_t)numEntries {
    NSMutableArray *levels = [[NSMutableArray alloc]initWithCapacity:numGroups];
    NSMutableArray *groups = [[NSMutableArray alloc]initWithCapacity:numGroups];
    [self read:inputStream toGroups:groups levels:levels numOfGroups:numGroups];
    
    NSMutableArray *entries = [[NSMutableArray alloc]initWithCapacity:numEntries]; 
    [self read:inputStream toEntries:entries numOfEntries:numEntries withGroups:groups];
    
    Kdb3Tree *tree = [self buildTree:groups levels:levels entries:entries];
    
    [groups release];
    [levels release];
    [entries release];
    
    return tree;
}

- (void)read:(InputStream*)inputStream toGroups:(NSMutableArray*)groups levels:(NSMutableArray*)levels numOfGroups:(uint32_t)numGroups {
    uint16_t fieldType;
    uint32_t fieldSize;
    uint8_t dateBuffer[5];
    
    // Parse the groups
    for (uint32_t i = 0; i < numGroups; i++) {
        Kdb3Group *group = [[Kdb3Group alloc] init];
        
        // Parse the fields
        do {
            fieldType = [inputStream readInt16];
            fieldType = CFSwapInt16LittleToHost(fieldType);

            fieldSize = [inputStream readInt32];
            fieldSize = CFSwapInt32LittleToHost(fieldSize);
            
            switch (fieldType) {
                case 0x0000:
                    if (fieldSize != 0) {
                        [group release];
                        @throw [NSException exceptionWithName:@"IOException" reason:@"Invalid field size" userInfo:nil];
                    }
                    break;
                    
                case 0x0001:
                    group.groupId = [inputStream readInt32];
                    group.groupId = CFSwapInt32LittleToHost(group.groupId);
                    break;
                
                case 0x0002:
                    group.name = [inputStream readCString:fieldSize encoding:NSUTF8StringEncoding];
                    break;
                
                case 0x0003:
                    [inputStream read:dateBuffer length:fieldSize];
                    group.creationTime = [Kdb3Date fromPacked:dateBuffer];
                    break;
                
                case 0x0004:
                    [inputStream read:dateBuffer length:fieldSize];
                    group.lastModificationTime = [Kdb3Date fromPacked:dateBuffer];
                    break;
                
                case 0x0005:
                    [inputStream read:dateBuffer length:fieldSize];
                    group.lastAccessTime = [Kdb3Date fromPacked:dateBuffer];
                    break;
                
                case 0x0006:
                    [inputStream read:dateBuffer length:fieldSize];
                    group.expiryTime = [Kdb3Date fromPacked:dateBuffer];
                    break;
                
                case 0x0007:
                    group.image = [inputStream readInt32];
                    group.image = CFSwapInt32LittleToHost(group.image);
                    break;
                
                case 0x0008: {
                    uint16_t level = [inputStream readInt16];
                    level = CFSwapInt16LittleToHost(level);
                    [levels addObject:[NSNumber numberWithUnsignedInteger:level]];
                    break;
                }
                
                case 0x0009:
                    group.flags = [inputStream readInt32];
                    group.flags = CFSwapInt32LittleToHost(group.flags);
                    break;
                
                case 0xFFFF:
                    if (fieldSize != 0) {
                        [group release];
                        @throw [NSException exceptionWithName:@"IOException" reason:@"Invalid field size" userInfo:nil];
                    }
                    break;
                
                default:
                    [group release];
                    @throw [NSException exceptionWithName:@"IOException" reason:@"Invalid field type" userInfo:nil];
            }
            
            if (fieldType == 0xFFFF) {
                [groups addObject:group];
                break;
            }
        } while(true);
        
        [group release];
    }
}

- (void)read:(InputStream*)inputStream toEntries:(NSMutableArray*)entries numOfEntries:(uint32_t)numEntries withGroups:(NSArray*)groups {
    uint16_t fieldType;
    uint32_t fieldSize;
    uint8_t buffer[16];
    uint32_t groupId;
    
    // Parse the entries
    for (uint32_t i = 0; i < numEntries; i++) {
        Kdb3Entry *entry = [[Kdb3Entry alloc]init];
        
        // Parse the field
        do {
            fieldType = [inputStream readInt16];
            fieldType = CFSwapInt16LittleToHost(fieldType);
            
            fieldSize = [inputStream readInt32];
            fieldSize = CFSwapInt32LittleToHost(fieldSize);
            
            switch (fieldType) {
                case 0x0000:
                    if (fieldSize != 0) {
                        [entry release];
                        @throw [NSException exceptionWithName:@"IOException" reason:@"Invalid field size" userInfo:nil];
                    }
                    break;
                    
                case 0x0001:
                    if (fieldSize != 16) {
                        [entry release];
                        @throw [NSException exceptionWithName:@"IOException" reason:@"Invalid field size" userInfo:nil];
                    }
                    if ([inputStream read:buffer length:fieldSize] != fieldSize) {
                        [entry release];
                        @throw [NSException exceptionWithName:@"IOException" reason:@"Failed to read UUID" userInfo:nil];
                    }
                    entry.uuid = [[[UUID alloc] initWithBytes:buffer] autorelease];
                    break; 
                
                case 0x0002:
                    groupId = [inputStream readInt32];
                    groupId = CFSwapInt32LittleToHost(groupId);
                    break;
                
                case 0x0003:
                    entry.image = [inputStream readInt32];
                    entry.image = CFSwapInt32LittleToHost(entry.image);
                    break;
                
                case 0x0004:
                    entry.title = [inputStream readCString:fieldSize encoding:NSUTF8StringEncoding];
                    break;
                
                case 0x0005:
                    entry.url = [inputStream readCString:fieldSize encoding:NSUTF8StringEncoding];
                    break;
                
                case 0x0006:
                    entry.username = [inputStream readCString:fieldSize encoding:NSUTF8StringEncoding];
                    break;
                
                case 0x0007:
                    entry.password = [inputStream readCString:fieldSize encoding:NSUTF8StringEncoding];
                    break;
                
                case 0x0008:
                    entry.notes = [inputStream readCString:fieldSize encoding:NSUTF8StringEncoding];
                    break;
                
                case 0x0009:
                    if (fieldSize != 5) {
                        [entry release];
                        @throw [NSException exceptionWithName:@"IOException" reason:@"Invalid field size" userInfo:nil];
                    }
                    [inputStream read:buffer length:fieldSize];
                    entry.creationTime = [Kdb3Date fromPacked:buffer];
                    break;
                
                case 0x000A:
                    if (fieldSize != 5) {
                        [entry release];
                        @throw [NSException exceptionWithName:@"IOException" reason:@"Invalid field size" userInfo:nil];
                    }
                    [inputStream read:buffer length:fieldSize];
                    entry.lastModificationTime = [Kdb3Date fromPacked:buffer];
                    break;
                
                case 0x000B:
                    if (fieldSize != 5) {
                        [entry release];
                        @throw [NSException exceptionWithName:@"IOException" reason:@"Invalid field size" userInfo:nil];
                    }
                    [inputStream read:buffer length:fieldSize];
                    entry.lastAccessTime = [Kdb3Date fromPacked:buffer];
                    break;
                
                case 0x000C:
                    if (fieldSize != 5) {
                        [entry release];
                        @throw [NSException exceptionWithName:@"IOException" reason:@"Invalid field size" userInfo:nil];
                    }
                    [inputStream read:buffer length:fieldSize];
                    entry.expiryTime = [Kdb3Date fromPacked:buffer];
                    break;
                
                case 0x000D:
                    entry.binaryDesc = [inputStream readCString:fieldSize encoding:NSUTF8StringEncoding];
                    break;
                
                case 0x000E:
                    if (fieldSize > 0) {
                        entry.binary = [inputStream readData:fieldSize];
                    }
                    break;
                    
                case 0xFFFF:
                    if (fieldSize != 0) {
                        [entry release];
                        @throw [NSException exceptionWithName:@"IOException" reason:@"Invalid field size" userInfo:nil];
                    }
                    break;
                
                default:
                    [entry release];
                    @throw [NSException exceptionWithName:@"IOException" reason:@"Invalid field type" userInfo:nil];
            }
            
            if (fieldType == 0xFFFF) {
                // Find the parent group
                for (Kdb3Group *g in groups) {
                    if (g.groupId == groupId) {
                        [g addEntry:entry];
                        break;
                    }
                }
                
                [entries addObject:entry];
                break;
            }
        } while(true);
        
        [entry release];
    }
}

- (Kdb3Tree*)buildTree:(NSArray*)groups levels:(NSArray*)levels entries:(NSArray*)entries {
    uint16_t level1;
    uint16_t level2;
    int i;
    int j;

    Kdb3Tree *tree = [[Kdb3Tree alloc] init];
    
    Kdb3Group *root = [[Kdb3Group alloc] init];
    root.name = @"$ROOT$";
    root.parent = nil;
    root.canAddEntries = NO;
    tree.root = root;
    
    // Find the parent for every group
    for (i = 0; i < [groups count]; i++) {
        Kdb3Group *group = [groups objectAtIndex:i];
        level1 = [[levels objectAtIndex:i] unsignedIntValue];
        
        if (level1 == 0) {
            [root addGroup:group];
            continue;
        }
        
        // The first item with a lower level is the parent
        for (j = i - 1; j >= 0; j--) {
            level2 = [[levels objectAtIndex:j] unsignedIntValue];
            if (level2 < level1) {
                if (level1 - level2 != 1) {
                    [tree release];
                    [root release];
                    @throw [NSException exceptionWithName:@"InvalidData" reason:@"InvalidTree" userInfo:nil];
                } else {
                    break;
                }
            }
            if (j == 0) {
                [tree release];
                [root release];
                @throw [NSException exceptionWithName:@"InvalidData" reason:@"InvalidTree" userInfo:nil];
            }
        }
        
        Kdb3Group *parent = [groups objectAtIndex:j];
        [parent addGroup:group];
    }
    
    [root release];

    return [tree autorelease];
}

@end
