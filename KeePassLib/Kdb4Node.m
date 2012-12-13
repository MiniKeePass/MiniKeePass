//
//  Kdb4Node.m
//  KeePass2
//
//  Created by Qiang Yu on 2/23/10.
//  Copyright 2010 Qiang Yu. All rights reserved.
//

#import "Kdb4Node.h"
#import "DDXMLElement+MKPAdditions.h"

#import "UUID.h"
#import "Kdb4Parser.h"

@implementation Kdb4Group

@synthesize element;

- (id)initWithElement:(DDXMLElement*)e {
    self = [super init];
    if (self) {
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
        DDXMLElement *root = ((Kdb4Group*)group.parent).element;
        [root removeChild:((Kdb4Group*)group).element];
        // QUESTION: Should update the modification time of parent?
        group.parent = nil;
    }
    
    [super removeGroup:group];
}

- (void)removeEntry:(KdbEntry*)entry {
    if (entry.parent != nil) {
        DDXMLElement *root = ((Kdb4Group*)entry.parent).element;
        [root removeChild:((Kdb4Group*)entry).element];
        // QUESTION: Should update the modification time of parent?
        entry.parent = nil;
    }
    
    [super removeEntry:entry];
}

@end


@implementation StringField

@synthesize parent;
@synthesize name;
@synthesize value;
@synthesize element;

- (id)initWithElement:(DDXMLElement *)e {
    self = [super init];
    if (self) {
        self.element = e;
    }
    return self;
}

- (void)dealloc {
    [parent release];
    [name release];
    [value release];
    [element release];
    [super dealloc];
}

@end


@implementation Kdb4Entry

@synthesize element;
@synthesize stringFields;

- (id)initWithElement:(DDXMLElement*)e {
    self = [super init];
    if (self) {
        self.element = e;
        self.stringFields = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)dealloc {
    [element release];
    [super dealloc];
}

- (void)addStringField:(StringField*)stringField {
    stringField.parent = self;
    [stringFields addObject:stringField];
}

- (void)removeStringField:(StringField*)stringField {
    if (stringField.parent != nil) {
        DDXMLElement *root = ((Kdb4Group*)stringField.parent).element;
        [root removeChild:stringField.element];
    }
    
    stringField.parent = nil;
    [stringFields removeObject:stringField];
}

@end


@implementation Kdb4Tree

@synthesize document;
@synthesize rounds;
@synthesize compressionAlgorithm;

- (id)initWithDocument:(DDXMLDocument*)doc {
    self = [super init];
    if (self) {
        self.document = doc;
        self.rounds = DEFAULT_TRANSFORMATION_ROUNDS;
        self.compressionAlgorithm = COMPRESSION_GZIP;
    }
    return self;
}

- (void)dealloc {
    [document release];
    [super dealloc];
}

- (DDXMLElement*)createTimesElement {
    DDXMLElement *element;
    
    DDXMLElement *rootElement = [DDXMLElement elementWithName:@"Times"];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.timeZone = [NSTimeZone timeZoneWithName:@"GMT"];
    dateFormatter.dateFormat = @"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'";
    NSString *currentTime = [dateFormatter stringFromDate:[NSDate date]];
#ifdef DEBUG
    // expected format 2012-12-01T13:53:18Z
    NSLog(@"current Time: %@",currentTime);
#endif
    [dateFormatter release];
    
    element = [DDXMLElement elementWithName:@"LastModificationTime" stringValue:currentTime];
    [rootElement addChild:element];
    
    element = [DDXMLElement elementWithName:@"CreationTime" stringValue:currentTime];
    [rootElement addChild:element];
    
    element = [DDXMLElement elementWithName:@"LastAccessTime" stringValue:currentTime];
    [rootElement addChild:element];
    
    element = [DDXMLElement elementWithName:@"ExpiryTime" stringValue:currentTime];
    [rootElement addChild:element];
    
    element = [DDXMLElement elementWithName:@"Expires" stringValue:@"False"];
    [rootElement addChild:element];
    
    element = [DDXMLElement elementWithName:@"UsageCount" stringValue:@"0"];
    [rootElement addChild:element];
    
    element = [DDXMLElement elementWithName:@"LocationChanged" stringValue:currentTime];
    [rootElement addChild:element];
    
    return rootElement;
}


- (DDXMLElement*)createAutoTypeElement {
    DDXMLElement *element;
    
    DDXMLElement *rootElement = [DDXMLElement elementWithName:@"AutoType"];
    
    DDXMLElement *associationElement = [DDXMLElement elementWithName:@"Association"];
    
    element = [DDXMLElement elementWithName:@"Window" stringValue:@"Target Window"];
    [associationElement addChild:element];
    
    element = [DDXMLElement elementWithName:@"KeystrokeSequence" stringValue:@"{USERNAME}{TAB}{PASSWORD}{TAB}{ENTER}"];
    [associationElement addChild:element];
    
    [rootElement addChild:associationElement];
    
    return rootElement;
}

- (DDXMLElement*)createStringElement:(NSString*)key value:(NSString*)value protected:(BOOL)protected {
    DDXMLElement *element;
    
    DDXMLElement *rootElement = [DDXMLElement elementWithName:@"String"];
    
    element = [DDXMLElement elementWithName:@"Key" stringValue:key];
    [rootElement addChild:element];
    
    element = [DDXMLElement elementWithName:@"Value" stringValue:value];
    if (protected) {
        [element addAttribute:[DDXMLElement attributeWithName:@"Protected" stringValue:@"True"]];
    }
    [rootElement addChild:element];
    
    return rootElement;
}
// only the DOM is valid after creation.
// HBXX maybe do a parseGroup? or make sure we update the datastructure
- (KdbGroup*)createGroup:(KdbGroup*)parent {
    DDXMLElement *element;
    
    Kdb4Group *group = [[Kdb4Group alloc] init];
    group.parent = parent;
    
    group.element = [DDXMLElement elementWithName:@"Group"];
    
    NSString* randomUUID = [[[[UUID alloc] init] autorelease] inBase64];
    element = [DDXMLElement elementWithName:@"UUID" stringValue:randomUUID];
#ifdef DEBUG
    NSLog(@"createGroup: UUID: %@",element.stringValue);
#endif
    [group.element addChild:element];
    
    element = [DDXMLElement elementWithName:@"Name" stringValue:@""];
    [group.element addChild:element];
    
    element = [DDXMLElement elementWithName:@"Notes" stringValue:@""];
    [group.element addChild:element];
    
    element = [DDXMLElement elementWithName:@"IconID" stringValue:@"0"];
    [group.element addChild:element];
    
    element = [self createTimesElement];
    [group.element addChild:element];

    // UPDATE group's structure
    // QUESTION: is this the best place?, groups are created when a file is created and when
    // group's are created via the UI
    Kdb4Parser* parser = [[[Kdb4Parser alloc] initWithRandomStream:nil] autorelease];
    [parser parseTimesElement:element intoGroup:group];

    
    
    element = [DDXMLElement elementWithName:@"IsExpanded" stringValue:@"True"];
    [group.element addChild:element];

    element = [DDXMLElement elementWithName:@"DefaultAutoTypeSequence"];
    [group.element addChild:element];
    
    element = [DDXMLElement elementWithName:@"EnableAutoType" stringValue:@"null"];
    [group.element addChild:element];
    
    element = [DDXMLElement elementWithName:@"EnableSearching" stringValue:@"null"];
    [group.element addChild:element];
    
    // WARNING: this might not be a randomUUID, find out from doc.
    // KeePassX expects it not to be empty.
    randomUUID = [[[[UUID alloc] init] autorelease] inBase64];
    element = [DDXMLElement elementWithName:@"LastTopVisibleEntry" stringValue:randomUUID];
#ifdef DEBUG
    NSLog(@"  LastTopVisibleEntry with UUID: %@",element.stringValue);
#endif
    [group.element addChild:element];
    // waiting for UUID here.
    
    
    // Add the root element to the parent group's element
    [((Kdb4Group*)parent).element addChild:group.element];
    
    return [group autorelease];
}

- (KdbEntry*)createEntry:(KdbGroup*)parent {
    DDXMLElement *element;
    
    Kdb4Entry *entry = [[Kdb4Entry alloc] init];
    entry.parent = parent;
    entry.element = [DDXMLElement elementWithName:@"Entry"];
    
    NSString* randomUUID = [[[[UUID alloc] init] autorelease] inBase64];
    element = [DDXMLElement elementWithName:@"UUID" stringValue:randomUUID];
#ifdef DEBUG
    NSLog(@"createEntry: UUID: %@",element.stringValue);
#endif
    [entry.element addChild:element];
    
    element = [DDXMLElement elementWithName:@"IconID" stringValue:@"0"];
    [entry.element addChild:element];
    
    element = [DDXMLElement elementWithName:@"ForegroundColor"];
    [entry.element addChild:element];
    
    element = [DDXMLElement elementWithName:@"BackgroundColor"];
    [entry.element addChild:element];
    
    element = [DDXMLElement elementWithName:@"OverrideURL"];
    [entry.element addChild:element];
    
    element = [DDXMLElement elementWithName:@"Tags"];
    [entry.element addChild:element];
    
    element = [self createTimesElement];
    [entry.element addChild:element];
    
    // UPDATE group's structure
    // QUESTION: is this the best place?, groups are created when a file is created and when
    // group's are created via the UI
    Kdb4Parser* parser = [[[Kdb4Parser alloc] initWithRandomStream:nil] autorelease];
    [parser parseTimesElement:element intoEntry:entry];

    
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
    
    element = [DDXMLElement elementWithName:@"History"];
    [entry.element addChild:element];
    
    // Add the root element to the parent group's element
    [((Kdb4Group*)parent).element addChild:entry.element];
    
    return [entry autorelease];
}

- (StringField*)createStringField:(Kdb4Entry*)parent {
    StringField *stringField = [[StringField alloc] init];
    stringField.parent = parent;
    stringField.element = [self createStringElement:@"" value:@"" protected:NO];
    
    [parent.element addChild:stringField.element];
    
    return [stringField autorelease];
}

@end
