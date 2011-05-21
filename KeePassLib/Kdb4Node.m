//
//  Kdb4Node.m
//  KeePass2
//
//  Created by Qiang Yu on 2/23/10.
//  Copyright 2010 Qiang Yu. All rights reserved.
//

#import "Kdb4Node.h"
#import "Utils.h"


#define K_NOTES "Notes"
#define K_PASSWORD "Password"
#define K_TITLE "Title"
#define K_URL "URL"
#define K_USERNAME "UserName"

@implementation Kdb4Group

@synthesize _element;
@synthesize _parent;
@synthesize _subGroups;
@synthesize _entries;

- (id)initWithElement:(GDataXMLElement*)element {
    self = [super init];
    if(self) {
        self._element = element;
    }
    return self;
}

- (void)dealloc {
    [_element release];
    [_subGroups release];
    [_entries release];
    [super dealloc];
}

- (NSUInteger)getImage {
    GDataXMLElement *element = [_element elementForName:@"IconID"];
    return element.stringValue.intValue;
}

- (void)setImage:(NSUInteger)image {
    // TODO
}

- (NSString*)getGroupName {
    GDataXMLElement *element = [_element elementForName:@"Name"];
    return element.stringValue;
}

- (void)setGroupName:(NSString*)groupName {
    // TODO
}

- (void)addEntry:(id<KdbEntry>)child {
    Kdb4Entry *entry = (Kdb4Entry*)child;
    entry._parent = self;
    if (!_entries) {
        _entries = [[NSMutableArray alloc] initWithCapacity:16];
    }
    [_entries addObject:child];
}

- (void)deleteEntry:(id<KdbEntry>)child {
    Kdb4Entry *entry = (Kdb4Entry*)child;
    entry._parent = nil;
    [_entries removeObject:child];
}

- (void)addSubGroup:(id<KdbGroup>)child{
    Kdb4Group *group = (Kdb4Group*)child;
    group._parent = self;
    if (!_subGroups) {
        _subGroups = [[NSMutableArray alloc] initWithCapacity:8];
    }
    [_subGroups addObject:child];
}

- (void)deleteSubGroup:(id<KdbGroup>)child {
    Kdb4Group *group = (Kdb4Group*)child;
    group._parent = nil;
    [_subGroups removeObject:child];
}

- (void)setCreation:(NSDate*)date {
    // TODO
}

- (void)setLastMod:(NSDate*)date {
    // TODO
}

- (void)setLastAccess:(NSDate*)date {
    // TODO
}

- (void)setExpiry:(NSDate*)date {
    // TODO
}

- (NSString*)description {
    return [NSString stringWithFormat:@"Kdb4Group [name=%@, image=%d", [self getGroupName], [self getImage]];
}

- (void)breakCyclcReference {
    self._parent = nil;
    for(Kdb4Group *group in _subGroups){
        [group breakCyclcReference];
    }
    
    for(Kdb4Entry *entry in _entries){
        [entry breakCyclcReference];
    }
}

@end


@implementation Kdb4Entry

@synthesize _element;
@synthesize _parent;

@synthesize _image;
@synthesize _entryName;
@synthesize _username;
@synthesize _password;
@synthesize _url;
@synthesize _comment;

- (id)initWithElement:(GDataXMLElement*)element {
    self = [super init];
    if(self) {
        self._element = element;
    }
    return self;
}

- (void)dealloc {
    [_element release];
    [super dealloc];
}

- (NSUInteger)getNumberOfCustomAttributes {
    return 0; // TODO
}

- (NSString*)getCustomAttributeName:(NSUInteger)index {
    return nil; // TODO
}

- (NSString*)getCustomAttributeValue:(NSUInteger)index {
    return nil; // TODO
}

- (void)setCreation:(NSDate*)date {
    // TODO
}

- (void)setLastMod:(NSDate*)date {
    // TODO
}

- (void)setLastAccess:(NSDate*)date {
    // TODO
}

- (void)setExpiry:(NSDate*)date {
    // TODO
}

- (NSString*)description {
    return [NSString stringWithFormat:@"Kdb4Entry [name=%@, image=%d", [self getEntryName], [self getImage]];
}

- (void)breakCyclcReference {
    self._parent = nil;
}

@end

@implementation Kdb4Tree

@synthesize _element;
@synthesize _root;
@synthesize _meta;

- (id)initWithElement:(GDataXMLElement*)element {
    self = [super init];
    if(self) {
        self._element = element;
    }
    return self;
}

- (void)dealloc {
    [_root release];
    [super dealloc];
}

- (BOOL)isRecycleBin:(id<KdbGroup>)group {
    return NO; // TODO
}

@end
