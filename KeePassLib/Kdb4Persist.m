//
//  Kdb4Persist.m
//  MobileKeePass
//
//  Created by Jason Rush on 5/26/11.
//  Copyright 2011 Self. All rights reserved.
//

#import "Kdb4Persist.h"

@interface Kdb4Persist (PrivateMethods)
- (void)updateGroup:(Kdb4Group*)group;
- (void)updateEntry:(Kdb4Entry*)entry;
@end

@implementation Kdb4Persist

- (id)initWithTree:(Kdb4Tree*)t andOutputStream:(OutputStream*)stream {
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
    // Update the DOM model
    [self updateGroup:(Kdb4Group*)tree.root];
    
    // FIXME Apply CSR to protected fields
    
    // Serialize the DOM to XML
    [outputStream write:[tree.document XMLData]];
}

- (void)updateGroup:(Kdb4Group*)group {
    GDataXMLElement *nameElement = [group.element elementForName:@"Name"];
    nameElement.stringValue = group.name;
    
    for (Kdb4Entry *entry in group.entries) {
        [self updateEntry:entry];
    }
    
    for (Kdb4Group *g in group.groups) {
        [self updateGroup:g];
    }
}

- (void)updateEntry:(Kdb4Entry*)entry {
    GDataXMLElement *root = entry.element;
    
    GDataXMLElement *iconElement = [root elementForName:@"IconID"];
    iconElement.stringValue = [NSString stringWithFormat:@"%d", entry.image];
    
    for (GDataXMLElement *element in [root elementsForName:@"String"]) {
        NSString *key = [[element elementForName:@"Key"] stringValue];
        
        GDataXMLElement *valueElement = [element elementForName:@"Value"];
        
        if ([key isEqualToString:@"Title"]) {
            valueElement.stringValue = entry.title;
        } else if ([key isEqualToString:@"UserName"]) {
            valueElement.stringValue = entry.username;
        } else if ([key isEqualToString:@"Password"]) {
            valueElement.stringValue = entry.password;
        } else if ([key isEqualToString:@"URL"]) {
            valueElement.stringValue = entry.url;
        } else if ([key isEqualToString:@"Notes"]) {
            valueElement.stringValue = entry.notes;
        }
    }
}

@end
