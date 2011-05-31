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
    
    element = [GDataXMLNode elementWithName:@"LastModificationTime"];
    [element setStringValue:currentTime];
    [rootElement addChild:element];
    
    element = [GDataXMLNode elementWithName:@"CreationTime"];
    [element setStringValue:currentTime];
    [rootElement addChild:element];
    
    element = [GDataXMLNode elementWithName:@"LastAccessTime"];
    [element setStringValue:currentTime];
    [rootElement addChild:element];
    
    element = [GDataXMLNode elementWithName:@"ExpiryTime"];
    [element setStringValue:currentTime];
    [rootElement addChild:element];
    
    element = [GDataXMLNode elementWithName:@"Expires"];
    [element setStringValue:@"False"];
    [rootElement addChild:element];
    
    element = [GDataXMLNode elementWithName:@"UsageCount"];
    [element setStringValue:@"0"];
    [rootElement addChild:element];
    
    element = [GDataXMLNode elementWithName:@"LocationChanged"];
    [element setStringValue:currentTime];
    [rootElement addChild:element];
    
    return rootElement;
}

- (GDataXMLElement*)createStringElement:(NSString*)key value:(NSString*)value protected:(BOOL)protected {
    GDataXMLElement *element;
    
    GDataXMLElement *rootElement = [GDataXMLNode elementWithName:@"String"];
    
    element = [GDataXMLNode elementWithName:@"Key"];
    [element setStringValue:key];
    [rootElement addChild:element];
    
    element = [GDataXMLNode elementWithName:@"Value"];
    if (protected) {
        [element addAttribute:[GDataXMLNode attributeWithName:@"Protected" stringValue:@"True"]];
    }
    [element setStringValue:value];
    
    [rootElement addChild:element];
    
    return rootElement;
}

- (KdbGroup*)createGroup:(KdbGroup*)parent {
    GDataXMLElement *element;
    
    Kdb4Group *group = [[Kdb4Group alloc] init];
    group.parent = parent;
    
    group.element = [GDataXMLNode elementWithName:@"Group"];
    [((Kdb4Group*)parent).element addChild:group.element];
    
    element = [GDataXMLNode elementWithName:@"UUID"];
    [element setStringValue:@"CHANGE_ME"];
    [group.element addChild:element];
    
    element = [GDataXMLNode elementWithName:@"Name"];
    [element setStringValue:@"CHANGE_ME"];
    [group.element addChild:element];
    
    element = [GDataXMLNode elementWithName:@"Notes"];
    [group.element addChild:element];
    
    element = [GDataXMLNode elementWithName:@"IconID"];
    [element setStringValue:@"0"];
    [group.element addChild:element];
    
    element = [self createTimesElement];
    [group.element addChild:element];
    
    element = [GDataXMLNode elementWithName:@"IsExpanded"];
    [element setStringValue:@"True"];
    [group.element addChild:element];

    element = [GDataXMLNode elementWithName:@"DefaultAutoTypeSequence"];
    [group.element addChild:element];
    
    element = [GDataXMLNode elementWithName:@"EnableAutoType"];
    [element setStringValue:@"null"];
    [group.element addChild:element];
    
    element = [GDataXMLNode elementWithName:@"EnableSearching"];
    [element setStringValue:@"null"];
    [group.element addChild:element];
    
    element = [GDataXMLNode elementWithName:@"LastTopVisibleEntry"];
    [element setStringValue:@"CHANGE_ME"];
    [group.element addChild:element];
    
    return [group autorelease];
}

- (KdbEntry*)createEntry:(KdbGroup*)parent {
    GDataXMLElement *element;
    
    Kdb4Entry *entry = [[Kdb4Entry alloc] init];
    entry.parent = parent;
    entry.element = [GDataXMLNode elementWithName:@"Entry"];
    [((Kdb4Group*)parent).element addChild:entry.element];
    
    element = [GDataXMLNode elementWithName:@"UUID"];
    [element setStringValue:@"CHANGE_ME"];
    [entry.element addChild:element];
    
    element = [GDataXMLNode elementWithName:@"IconID"];
    [element setStringValue:@"0"];
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
    
    element = [self createStringElement:@"Notes" value:@"CHANGE_ME" protected:NO];
    [entry.element addChild:element];
    
    element = [self createStringElement:@"Password" value:@"CHANGE_ME" protected:NO];
    [entry.element addChild:element];
    
    element = [self createStringElement:@"Title" value:@"CHANGE_ME" protected:NO];
    [entry.element addChild:element];
    
    element = [self createStringElement:@"URL" value:@"CHANGE_ME" protected:NO];
    [entry.element addChild:element];
    
    element = [self createStringElement:@"UserName" value:@"CHANGE_ME" protected:NO];
    [entry.element addChild:element];
    
    // FIXME Implement the autotype element
    //element = [GDataXMLNode elementWithName:@"AutoType"];
    //[entry.element addChild:element];
    
    element = [GDataXMLNode elementWithName:@"History"];
    [entry.element addChild:element];
    
    return [entry autorelease];
}

@end
