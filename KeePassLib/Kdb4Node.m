//
//  Kdb4Node.m
//  KeePass2
//
//  Created by Qiang Yu on 2/23/10.
//  Copyright 2010 Qiang Yu. All rights reserved.
//

#import "Kdb4Node.h"

@implementation Kdb4Group

@synthesize element;

- (id)initWithElement:(GDataXMLElement*)e {
    self = [super init];
    if(self) {
        self.element = e;
    }
    return self;
}

- (void)dealloc {
    [element release];
    [super dealloc];
}

- (void)removeGroup:(KdbGroup*)group {
    if (group.parent != nil) {
        GDataXMLElement *root = ((Kdb4Group*)group.parent).element;
        [root removeChild:((Kdb4Group*)group).element];
        group.parent = nil;
    }
    
    [super removeGroup:group];
}

- (void)removeEntry:(KdbEntry*)entry {
    if (entry.parent != nil) {
        GDataXMLElement *root = ((Kdb4Group*)entry.parent).element;
        [root removeChild:((Kdb4Group*)entry).element];
        entry.parent = nil;
    }
    
    [super removeEntry:entry];
}

@end


@implementation Kdb4Entry

@synthesize element;

- (id)initWithElement:(GDataXMLElement*)e {
    self = [super init];
    if(self) {
        self.element = e;
    }
    return self;
}

- (void)dealloc {
    [element release];
    [super dealloc];
}

@end


@implementation Kdb4Tree

@synthesize document;

- (id)initWithDocument:(GDataXMLDocument*)doc {
    self = [super init];
    if(self) {
        self.document = doc;
    }
    return self;
}

- (void)dealloc {
    [document release];
    [super dealloc];
}

- (GDataXMLElement*)createTimesElement {
    GDataXMLElement *element;
    
    GDataXMLElement *rootElement = [GDataXMLNode elementWithName:@"Times"];
    
    NSString *currentTime = @"CHANGE_ME";
    
    element = [GDataXMLNode elementWithName:@"LastModificationTime" stringValue:currentTime];
    [rootElement addChild:element];
    
    element = [GDataXMLNode elementWithName:@"CreationTime" stringValue:currentTime];
    [rootElement addChild:element];
    
    element = [GDataXMLNode elementWithName:@"LastAccessTime" stringValue:currentTime];
    [rootElement addChild:element];
    
    element = [GDataXMLNode elementWithName:@"ExpiryTime" stringValue:currentTime];
    [rootElement addChild:element];
    
    element = [GDataXMLNode elementWithName:@"Expires" stringValue:@"False"];
    [rootElement addChild:element];
    
    element = [GDataXMLNode elementWithName:@"UsageCount" stringValue:@"0"];
    [rootElement addChild:element];
    
    element = [GDataXMLNode elementWithName:@"LocationChanged" stringValue:currentTime];
    [rootElement addChild:element];
    
    return rootElement;
}


- (GDataXMLElement*)createAutoTypeElement {
    GDataXMLElement *element;
    
    GDataXMLElement *rootElement = [GDataXMLNode elementWithName:@"AutoType"];
    
    GDataXMLElement *associationElement = [GDataXMLNode elementWithName:@"Association"];
    
    element = [GDataXMLNode elementWithName:@"Window" stringValue:@"Target Window"];
    [associationElement addChild:element];
    
    element = [GDataXMLNode elementWithName:@"KeystrokeSequence" stringValue:@"{USERNAME}{TAB}{PASSWORD}{TAB}{ENTER}"];
    [associationElement addChild:element];
    
    [rootElement addChild:associationElement];
    
    return rootElement;
}

- (GDataXMLElement*)createStringElement:(NSString*)key value:(NSString*)value protected:(BOOL)protected {
    GDataXMLElement *element;
    
    GDataXMLElement *rootElement = [GDataXMLNode elementWithName:@"String"];
    
    element = [GDataXMLNode elementWithName:@"Key" stringValue:key];
    [rootElement addChild:element];
    
    element = [GDataXMLNode elementWithName:@"Value" stringValue:value];
    if (protected) {
        [element addAttribute:[GDataXMLNode attributeWithName:@"Protected" stringValue:@"True"]];
    }
    [rootElement addChild:element];
    
    return rootElement;
}

- (KdbGroup*)createGroup:(KdbGroup*)parent {
    GDataXMLElement *element;
    
    Kdb4Group *group = [[Kdb4Group alloc] init];
    group.parent = parent;
    
    group.element = [GDataXMLNode elementWithName:@"Group"];
    
    element = [GDataXMLNode elementWithName:@"UUID" stringValue:@""];
    [group.element addChild:element];
    
    element = [GDataXMLNode elementWithName:@"Name" stringValue:@""];
    [group.element addChild:element];
    
    element = [GDataXMLNode elementWithName:@"Notes" stringValue:@""];
    [group.element addChild:element];
    
    element = [GDataXMLNode elementWithName:@"IconID" stringValue:@"0"];
    [group.element addChild:element];
    
    element = [self createTimesElement];
    [group.element addChild:element];
    
    element = [GDataXMLNode elementWithName:@"IsExpanded" stringValue:@"True"];
    [group.element addChild:element];

    element = [GDataXMLNode elementWithName:@"DefaultAutoTypeSequence"];
    [group.element addChild:element];
    
    element = [GDataXMLNode elementWithName:@"EnableAutoType" stringValue:@"null"];
    [group.element addChild:element];
    
    element = [GDataXMLNode elementWithName:@"EnableSearching" stringValue:@"null"];
    [group.element addChild:element];
    
    element = [GDataXMLNode elementWithName:@"LastTopVisibleEntry" stringValue:@""];
    [group.element addChild:element];
    
    // Add the root element to the parent group's element
    [((Kdb4Group*)parent).element addChild:group.element];
    
    return [group autorelease];
}

- (KdbEntry*)createEntry:(KdbGroup*)parent {
    GDataXMLElement *element;
    
    Kdb4Entry *entry = [[Kdb4Entry alloc] init];
    entry.parent = parent;
    entry.element = [GDataXMLNode elementWithName:@"Entry"];
    
    element = [GDataXMLNode elementWithName:@"UUID" stringValue:@""];
    [entry.element addChild:element];
    
    element = [GDataXMLNode elementWithName:@"IconID" stringValue:@"0"];
    [entry.element addChild:element];
    
    element = [GDataXMLNode elementWithName:@"ForegroundColor"];
    [entry.element addChild:element];
    
    element = [GDataXMLNode elementWithName:@"BackgroundColor"];
    [entry.element addChild:element];
    
    element = [GDataXMLNode elementWithName:@"OverrideURL"];
    [entry.element addChild:element];
    
    element = [GDataXMLNode elementWithName:@"Tags"];
    [entry.element addChild:element];
    
    element = [self createTimesElement];
    [entry.element addChild:element];
    
    element = [self createStringElement:@"Notes" value:@"" protected:NO];
    [entry.element addChild:element];
    
    element = [self createStringElement:@"Password" value:@"" protected:NO];
    [entry.element addChild:element];
    
    element = [self createStringElement:@"Title" value:@"" protected:NO];
    [entry.element addChild:element];
    
    element = [self createStringElement:@"URL" value:@"" protected:NO];
    [entry.element addChild:element];
    
    element = [self createStringElement:@"UserName" value:@"" protected:NO];
    [entry.element addChild:element];
    
    element = [self createAutoTypeElement];
    [entry.element addChild:element];
    
    element = [GDataXMLNode elementWithName:@"History"];
    [entry.element addChild:element];
    
    // Add the root element to the parent group's element
    [((Kdb4Group*)parent).element addChild:entry.element];
    
    return [entry autorelease];
}

@end
