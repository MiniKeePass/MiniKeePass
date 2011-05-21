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
@synthesize _image;
@synthesize _groupName;
@synthesize _subGroups;
@synthesize _entries;
@synthesize _creationDate;
@synthesize _lastModifiedDate;
@synthesize _lastAccessDate;
@synthesize _expirationDate;

- (id)initWithElement:(GDataXMLElement*)element {
    self = [super init];
    if(self) {
        self._element = element;
    }
    return self;
}

- (void)dealloc {
    [_element release];
    [_groupName release];
    [_subGroups release];
    [_entries release];
    [super dealloc];
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

- (NSString*)description {
    return [NSString stringWithFormat:@"Kdb4Group [name=%@, image=%d", [self getGroupName], [self getImage]];
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
@synthesize _creationDate;
@synthesize _lastModifiedDate;
@synthesize _lastAccessDate;
@synthesize _expirationDate;

- (id)initWithElement:(GDataXMLElement*)element {
    self = [super init];
    if(self) {
        self._element = element;
    }
    return self;
}

- (void)dealloc {
    [_element release];
    [_entryName release];
    [_username release];
    [_password release];
    [_url release];
    [_comment release];
    [super dealloc];
}

- (NSString*)description {
    return [NSString stringWithFormat:@"Kdb4Entry [name=%@, image=%d", [self getEntryName], [self getImage]];
}

@end

@implementation Kdb4Tree

@synthesize _document;
@synthesize _root;
@synthesize _meta;

- (id)initWithDocument:(GDataXMLDocument*)document {
    self = [super init];
    if(self) {
        self._document = document;
    }
    return self;
}

- (void)dealloc {
    [_document release];
    [_root release];
    [_meta release];
    [super dealloc];
}

- (BOOL)isRecycleBin:(id<KdbGroup>)group {
    return NO; // TODO
}

@end
