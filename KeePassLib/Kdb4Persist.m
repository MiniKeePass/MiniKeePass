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
#import "DDXML.h"
#import "DDXMLElementAdditions.h"

@interface Kdb4Persist (PrivateMethods)
- (void)updateGroup:(Kdb4Group*)group;
- (void)updateEntry:(Kdb4Entry*)entry;
- (void)encodeProtected:(DDXMLElement*)root;
- (void)decodeProtected:(DDXMLElement*)root;
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
    DDXMLDocument *document = [self persistTree];

    NSLog(@"%@", document);

    // Encode all the protected entries
    [self encodeProtected:document.rootElement];

    // Serialize the DOM to XML
    [outputStream write:[document XMLData]];
}

- (DDXMLDocument *)persistTree {
    DDXMLDocument *document = [[DDXMLDocument alloc] initWithXMLString:@"<KeePassFile></KeePassFile>" options:0 error:nil];

    DDXMLElement *element = [DDXMLNode elementWithName:@"Root"];
    [element addChild:[self persistGroup:(Kdb4Group *)tree.root]];
    [document.rootElement addChild:element];

    return document;
}

- (DDXMLElement *)persistGroup:(Kdb4Group *)group {
    DDXMLElement *root = [DDXMLNode elementWithName:@"Group"];

    // Add the standard properties
    [root addChild:[DDXMLNode elementWithName:@"UUID"
                                  stringValue:[group.uuid description]]];
    [root addChild:[DDXMLNode elementWithName:@"Name"
                                     stringValue:group.name]];
    [root addChild:[DDXMLNode elementWithName:@"IconID"
                                     stringValue:[NSString stringWithFormat:@"%d", group.image]]];
    [root addChild:[DDXMLNode elementWithName:@"Notes"
                                  stringValue:group.notes]];

    // Add the Times element
    DDXMLElement *timesElement = [DDXMLNode elementWithName:@"Times"];
    [timesElement addChild:[DDXMLNode elementWithName:@"LastModificationTime"
                                          stringValue:[dateFormatter stringFromDate:group.lastModificationTime]]];
    [timesElement addChild:[DDXMLNode elementWithName:@"CreationTime"
                                             stringValue:[dateFormatter stringFromDate:group.creationTime]]];
    [timesElement addChild:[DDXMLNode elementWithName:@"LastAccessTime"
                                             stringValue:[dateFormatter stringFromDate:group.lastAccessTime]]];
    [timesElement addChild:[DDXMLNode elementWithName:@"ExpiryTime"
                                          stringValue:[dateFormatter stringFromDate:group.expiryTime]]];
    [timesElement addChild:[DDXMLNode elementWithName:@"Expires"
                                          stringValue:group.expires ? @"True" : @"False"]];
    [timesElement addChild:[DDXMLNode elementWithName:@"UsageCount"
                                          stringValue:[NSString stringWithFormat:@"%d", group.usageCount]]];
    [timesElement addChild:[DDXMLNode elementWithName:@"LocationChanged"
                                          stringValue:[dateFormatter stringFromDate:group.locationChanged]]];
    [root addChild:timesElement];

    // Add the additional properties
    [root addChild:[DDXMLNode elementWithName:@"IsExpanded"
                                  stringValue:group.isExpanded ? @"True" : @"False"]];
    [root addChild:[DDXMLNode elementWithName:@"DefaultAutoTypeSequence"
                                  stringValue:group.defaultAutoTypeSequence]];
    [root addChild:[DDXMLNode elementWithName:@"EnableAutoType"
                                  stringValue:group.enableAutoType]];
    [root addChild:[DDXMLNode elementWithName:@"EnableSearching"
                                  stringValue:group.enableSearching]];
    [root addChild:[DDXMLNode elementWithName:@"LastTopVisibleEntry"
                                  stringValue:group.lastTopVisibleEntry]];

    for (Kdb4Entry *entry in group.entries) {
        [root addChild:[self persistEntry:entry]];
    }
    
    for (Kdb4Group *subGroup in group.groups) {
        [root addChild:[self persistGroup:subGroup]];
    }

    return root;
}

- (DDXMLElement *)persistEntry:(Kdb4Entry *)entry {
    DDXMLElement *root = [DDXMLNode elementWithName:@"Entry"];

    // Add the standard properties
    [root addChild:[DDXMLNode elementWithName:@"UUID"
                                  stringValue:[entry.uuid description]]];
    [root addChild:[DDXMLNode elementWithName:@"IconID"
                                     stringValue:[NSString stringWithFormat:@"%d", entry.image]]];
    [root addChild:[DDXMLNode elementWithName:@"ForegroundColor"
                                  stringValue:entry.foregroundColor]];
    [root addChild:[DDXMLNode elementWithName:@"BackgroundColor"
                                  stringValue:entry.backgroundColor]];
    [root addChild:[DDXMLNode elementWithName:@"OverrideURL"
                                  stringValue:entry.overrideUrl]];
    [root addChild:[DDXMLNode elementWithName:@"Tags"
                                  stringValue:entry.tags]];

    // Add the Times element
    DDXMLElement *timesElement = [DDXMLNode elementWithName:@"Times"];
    [timesElement addChild:[DDXMLNode elementWithName:@"LastModificationTime"
                                          stringValue:[dateFormatter stringFromDate:entry.lastModificationTime]]];
    [timesElement addChild:[DDXMLNode elementWithName:@"CreationTime"
                                          stringValue:[dateFormatter stringFromDate:entry.creationTime]]];
    [timesElement addChild:[DDXMLNode elementWithName:@"LastAccessTime"
                                          stringValue:[dateFormatter stringFromDate:entry.lastAccessTime]]];
    [timesElement addChild:[DDXMLNode elementWithName:@"ExpiryTime"
                                          stringValue:[dateFormatter stringFromDate:entry.expiryTime]]];
    [timesElement addChild:[DDXMLNode elementWithName:@"Expires"
                                          stringValue:entry.expires ? @"True" : @"False"]];
    [timesElement addChild:[DDXMLNode elementWithName:@"UsageCount"
                                          stringValue:[NSString stringWithFormat:@"%d", entry.usageCount]]];
    [timesElement addChild:[DDXMLNode elementWithName:@"LocationChanged"
                                          stringValue:[dateFormatter stringFromDate:entry.locationChanged]]];
    [root addChild:timesElement];

    // Add the standard string fields
    [root addChild:[self persistStringFieldWithKey:@"Title" andValue:entry.title andProtected:false]];
    [root addChild:[self persistStringFieldWithKey:@"UserName" andValue:entry.username andProtected:false]];
    [root addChild:[self persistStringFieldWithKey:@"Password" andValue:entry.password andProtected:true]];
    [root addChild:[self persistStringFieldWithKey:@"URL" andValue:entry.url andProtected:false]];
    [root addChild:[self persistStringFieldWithKey:@"Notes" andValue:entry.notes andProtected:false]];

    // Add the string fields
    for (StringField *stringField in entry.stringFields) {
        [root addChild:[self persistStringField:stringField]];
    }

    // FIXME Auto-type stuff goes here

    return root;
}

- (DDXMLElement *)persistStringFieldWithKey:(NSString *)key andValue:(NSString *)value andProtected:(BOOL)protected {
    DDXMLElement *root = [DDXMLNode elementWithName:@"String"];

    [root addChild:[DDXMLElement elementWithName:@"Key" stringValue:key]];
    
    DDXMLElement *element = [DDXMLElement elementWithName:@"Value" stringValue:value];
    if (protected) {
        [element addAttributeWithName:@"Protected" stringValue:@"True"];
    }
    [root addChild:element];

    return root;
}

- (DDXMLElement *)persistStringField:(StringField *)stringField {
    return [self persistStringFieldWithKey:stringField.key andValue:stringField.value andProtected:stringField.protected];
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

- (void)decodeProtected:(DDXMLElement*)root {
    DDXMLNode *protectedAttribute = [root attributeForName:@"Protected"];
    if ([[protectedAttribute stringValue] isEqual:@"True"]) {
        NSString *str = [root stringValue];
        
        // Base64 decode the string
        NSMutableData *data = [Base64 decode:[str dataUsingEncoding:NSASCIIStringEncoding]];
        
        // Unprotect the password
        [randomStream xor:data];

        NSString *unprotected = [[NSString alloc] initWithBytes:data.bytes length:data.length encoding:NSUTF8StringEncoding];
        [root setStringValue:unprotected];
        [unprotected release];
    }
    
    for (DDXMLNode *node in [root children]) {
        if ([node kind] == DDXMLElementKind) {
            [self decodeProtected:(DDXMLElement*)node];
        }
    }
}

@end
