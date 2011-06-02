/*
 * Copyright 2011 Jason Rush and John Flanagan. All rights reserved.
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#import "Kdb4Persist.h"
#import "Base64.h"

@interface Kdb4Persist (PrivateMethods)
- (void)updateGroup:(Kdb4Group*)group;
- (void)updateEntry:(Kdb4Entry*)entry;
- (void)encodeProtected:(GDataXMLElement*)root;
@end

@implementation Kdb4Persist

- (id)initWithTree:(Kdb4Tree*)t outputStream:(OutputStream*)stream randomStream:(id<RandomStream>)cryptoRandomStream {
    self = [super init];
    if (self) {
        tree = [t retain];
        outputStream = [stream retain];
        randomStream = [cryptoRandomStream retain];
    }
    return self;
}

- (void)dealloc {
    [tree release];
    [outputStream release];
    [randomStream release];
    [super dealloc];
}

- (void)persist {
    // Update the DOM model
    [self updateGroup:(Kdb4Group*)tree.root];
    
    // Apply CSR to protected fields
    [self encodeProtected:tree.document.rootElement];
    
    // Serialize the DOM to XML
    [outputStream write:[tree.document XMLData]];
}

- (void)updateGroup:(Kdb4Group*)group {
    GDataXMLElement *element;
    
    element = [group.element elementForName:@"Name"];
    element.stringValue = group.name;
    
    element = [group.element elementForName:@"IconID"];
    element.stringValue = [NSString stringWithFormat:@"%d", group.image];
    
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

- (void)encodeProtected:(GDataXMLElement*)root {
    GDataXMLNode *protectedAttribute = [root attributeForName:@"Protected"];
    if ([[protectedAttribute stringValue] isEqual:@"True"]) {
        NSString *str = [root stringValue];
        NSMutableData *data = [[str dataUsingEncoding:NSUTF8StringEncoding] mutableCopy];
        
        // Unprotect the password
        [randomStream xor:data];
        
        // Base64 encode the string
        data = [Base64 encode:data];
        
        NSString *protected = [[NSString alloc] initWithBytes:data.bytes length:data.length encoding:NSUTF8StringEncoding];
        [root setStringValue:protected];
        [protected release];
    }
    
    for (GDataXMLNode *node in [root children]) {
        if ([node kind] == GDataXMLElementKind) {
            [self encodeProtected:(GDataXMLElement*)node];
        }
    }
}

@end
