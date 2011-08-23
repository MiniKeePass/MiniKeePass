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
- (void)encodeProtected:(DDXMLElement*)root;
@end

@implementation Kdb4Persist

- (id)initWithTree:(Kdb4Tree*)t outputStream:(OutputStream*)stream randomStream:(RandomStream*)cryptoRandomStream {
    self = [super init];
    if (self) {
        tree = [t retain];
        outputStream = [stream retain];
        randomStream = [cryptoRandomStream retain];
        
        dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.timeZone = [NSTimeZone timeZoneWithName:@"GMT"];
        dateFormatter.dateFormat = @"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'";
    }
    return self;
}

- (void)dealloc {
    [tree release];
    [outputStream release];
    [randomStream release];
    [dateFormatter release];
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
    DDXMLElement *element;
    
    element = [group.element elementForName:@"Name"];
    element.stringValue = group.name;
    
    element = [group.element elementForName:@"IconID"];
    element.stringValue = [NSString stringWithFormat:@"%d", group.image];
    
    DDXMLElement *timesElement = [group.element elementForName:@"Times"];
    
    element = [timesElement elementForName:@"CreationTime"];
    element.stringValue = [dateFormatter stringFromDate:group.creationTime];
    
    element = [timesElement elementForName:@"LastModificationTime"];
    element.stringValue = [dateFormatter stringFromDate:group.lastModificationTime];
    
    element = [timesElement elementForName:@"LastAccessTime"];
    element.stringValue = [dateFormatter stringFromDate:group.lastAccessTime];
    
    element = [timesElement elementForName:@"ExpiryTime"];
    element.stringValue = [dateFormatter stringFromDate:group.expiryTime];
    
    for (Kdb4Entry *entry in group.entries) {
        [self updateEntry:entry];
    }
    
    for (Kdb4Group *g in group.groups) {
        [self updateGroup:g];
    }
}

- (void)updateEntry:(Kdb4Entry*)entry {
    DDXMLElement *root = entry.element;
    
    DDXMLElement *iconElement = [root elementForName:@"IconID"];
    iconElement.stringValue = [NSString stringWithFormat:@"%d", entry.image];
    
    DDXMLElement *timesElement = [entry.element elementForName:@"Times"];
    
    DDXMLElement *timeElement = [timesElement elementForName:@"CreationTime"];
    timeElement.stringValue = [dateFormatter stringFromDate:entry.creationTime];
    
    timeElement = [timesElement elementForName:@"LastModificationTime"];
    timeElement.stringValue = [dateFormatter stringFromDate:entry.lastModificationTime];
    
    timeElement = [timesElement elementForName:@"LastAccessTime"];
    timeElement.stringValue = [dateFormatter stringFromDate:entry.lastAccessTime];
    
    timeElement = [timesElement elementForName:@"ExpiryTime"];
    timeElement.stringValue = [dateFormatter stringFromDate:entry.expiryTime];
    
    for (DDXMLElement *element in [root elementsForName:@"String"]) {
        NSString *key = [[element elementForName:@"Key"] stringValue];
        
        DDXMLElement *valueElement = [element elementForName:@"Value"];
        
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

- (void)encodeProtected:(DDXMLElement*)root {
    DDXMLNode *protectedAttribute = [root attributeForName:@"Protected"];
    if ([[protectedAttribute stringValue] isEqual:@"True"]) {
        NSString *str = [root stringValue];
        NSMutableData *mutableData = [[str dataUsingEncoding:NSUTF8StringEncoding] mutableCopy];
        
        // Unprotect the password
        [randomStream xor:mutableData];
        
        // Base64 encode the string
        NSData *data = [Base64 encode:mutableData];
        
        [mutableData release];
        
        NSString *protected = [[NSString alloc] initWithBytes:data.bytes length:data.length encoding:NSUTF8StringEncoding];
        [root setStringValue:protected];
        [protected release];
    }
    
    for (DDXMLNode *node in [root children]) {
        if ([node kind] == DDXMLElementKind) {
            [self encodeProtected:(DDXMLElement*)node];
        }
    }
}

@end
