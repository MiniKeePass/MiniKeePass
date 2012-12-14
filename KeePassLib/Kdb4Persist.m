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
- (DDXMLDocument *)persistTree;
- (DDXMLElement *)persistBinary:(Binary *)binary;
- (DDXMLElement *)persistCustomItem:(CustomItem *)customItem;
- (DDXMLElement *)persistGroup:(Kdb4Group *)group;
- (DDXMLElement *)persistEntry:(Kdb4Entry *)entry includeHistory:(BOOL)includeHistory;
- (DDXMLElement *)persistStringField:(StringField *)stringField;
- (DDXMLElement *)persistBinaryRef:(BinaryRef *)binaryRef;
- (DDXMLElement *)persistAutoType:(AutoType *)autoType;
- (NSString *)persistUuid:(UUID *)uuid;
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
    DDXMLDocument *document = [self persistTree];

    // Encode all the protected entries
    [self encodeProtected:document.rootElement];

    // Serialize the DOM to XML
    [outputStream write:[document XMLData]];
}

- (DDXMLDocument *)persistTree {
    DDXMLElement *element;

    DDXMLDocument *document = [[DDXMLDocument alloc] initWithXMLString:@"<KeePassFile></KeePassFile>" options:0 error:nil];

    element = [DDXMLNode elementWithName:@"Meta"];
    [element addChild:[DDXMLNode elementWithName:@"Generator"
                                     stringValue:tree.generator]];
    [element addChild:[DDXMLNode elementWithName:@"DatabaseName"
                                     stringValue:tree.databaseName]];
    [element addChild:[DDXMLNode elementWithName:@"DatabaseNameChanged"
                                     stringValue:[dateFormatter stringFromDate:tree.databaseNameChanged]]];
    [element addChild:[DDXMLNode elementWithName:@"DatabaseDescription"
                                     stringValue:tree.databaseDescription]];
    [element addChild:[DDXMLNode elementWithName:@"DatabaseDescriptionChanged"
                                     stringValue:[dateFormatter stringFromDate:tree.databaseDescriptionChanged]]];
    [element addChild:[DDXMLNode elementWithName:@"DefaultUserName"
                                     stringValue:tree.defaultUserName]];
    [element addChild:[DDXMLNode elementWithName:@"DefaultUserNameChanged"
                                     stringValue:[dateFormatter stringFromDate:tree.defaultUserNameChanged]]];
    [element addChild:[DDXMLNode elementWithName:@"MaintenanceHistoryDays"
                                     stringValue:[NSString stringWithFormat:@"%d", tree.maintenanceHistoryDays]]];
    [element addChild:[DDXMLNode elementWithName:@"Color"
                                     stringValue:tree.color]];
    [element addChild:[DDXMLNode elementWithName:@"MasterKeyChanged"
                                     stringValue:[dateFormatter stringFromDate:tree.masterKeyChanged]]];
    [element addChild:[DDXMLNode elementWithName:@"MasterKeyChangeRec"
                                     stringValue:[NSString stringWithFormat:@"%d", tree.masterKeyChangeRec]]];
    [element addChild:[DDXMLNode elementWithName:@"MasterKeyChangeForce"
                                     stringValue:[NSString stringWithFormat:@"%d", tree.masterKeyChangeForce]]];

    DDXMLElement *protectionElement = [DDXMLElement elementWithName:@"MemoryProtection"];
    [protectionElement addChild:[DDXMLNode elementWithName:@"ProtectTitle"
                                               stringValue:tree.protectTitle ? @"True" : @"False"]];
    [protectionElement addChild:[DDXMLNode elementWithName:@"ProtectUserName"
                                               stringValue:tree.protectUserName ? @"True" : @"False"]];
    [protectionElement addChild:[DDXMLNode elementWithName:@"ProtectPassword"
                                               stringValue:tree.protectPassword ? @"True" : @"False"]];
    [protectionElement addChild:[DDXMLNode elementWithName:@"ProtectURL"
                                               stringValue:tree.protectUrl ? @"True" : @"False"]];
    [protectionElement addChild:[DDXMLNode elementWithName:@"ProtectNotes"
                                               stringValue:tree.protectNotes ? @"True" : @"False"]];
    [element addChild:protectionElement];

    [element addChild:[DDXMLNode elementWithName:@"RecycleBinEnabled"
                                     stringValue:tree.recycleBinEnabled ? @"True" : @"False"]];
    [element addChild:[DDXMLNode elementWithName:@"RecycleBinUUID"
                                     stringValue:[self persistUuid:tree.recycleBinUuid]]];
    [element addChild:[DDXMLNode elementWithName:@"RecycleBinChanged"
                                     stringValue:[dateFormatter stringFromDate:tree.recycleBinChanged]]];
    [element addChild:[DDXMLNode elementWithName:@"EntryTemplatesGroup"
                                     stringValue:[self persistUuid:tree.entryTemplatesGroup]]];
    [element addChild:[DDXMLNode elementWithName:@"EntryTemplatesGroupChanged"
                                     stringValue:[dateFormatter stringFromDate:tree.entryTemplatesGroupChanged]]];
    [element addChild:[DDXMLNode elementWithName:@"HistoryMaxItems"
                                     stringValue:[NSString stringWithFormat:@"%d", tree.historyMaxItems]]];
    [element addChild:[DDXMLNode elementWithName:@"HistoryMaxSize"
                                     stringValue:[NSString stringWithFormat:@"%d", tree.historyMaxSize]]];
    [element addChild:[DDXMLNode elementWithName:@"LastSelectedGroup"
                                     stringValue:[self persistUuid:tree.lastSelectedGroup]]];
    [element addChild:[DDXMLNode elementWithName:@"LastTopVisibleGroup"
                                     stringValue:[self persistUuid:tree.lastTopVisibleGroup]]];

    DDXMLElement *binaryElements = [DDXMLElement elementWithName:@"Binaries"];
    for (Binary *binary in tree.binaries) {
        [binaryElements addChild:[self persistBinary:binary]];
    }
    [element addChild:binaryElements];

    DDXMLElement *customDataElements = [DDXMLElement elementWithName:@"CustomData"];
    for (CustomItem *customItem in tree.customData) {
        [customDataElements addChild:[self persistCustomItem:customItem]];
    }
    [element addChild:customDataElements];

    [document.rootElement addChild:element];

    element = [DDXMLNode elementWithName:@"Root"];
    [element addChild:[self persistGroup:(Kdb4Group *)tree.root]];
    [document.rootElement addChild:element];

    return document;
}

- (DDXMLElement *)persistBinary:(Binary *)binary {
    DDXMLElement *root = [DDXMLNode elementWithName:@"Binary"];

    [root addAttributeWithName:@"ID" stringValue:[NSString stringWithFormat:@"%d", binary.binaryId]];
    [root addAttributeWithName:@"Compressed" stringValue:binary.compressed ? @"True" : @"False"];
    root.stringValue = binary.data;

    return root;
}

- (DDXMLElement *)persistCustomItem:(CustomItem *)customItem {
    DDXMLElement *root = [DDXMLNode elementWithName:@"Item"];

    [root addAttributeWithName:@"Key" stringValue:customItem.key];
    [root addAttributeWithName:@"Value" stringValue:customItem.value];

    return root;
}

- (DDXMLElement *)persistGroup:(Kdb4Group *)group {
    DDXMLElement *root = [DDXMLNode elementWithName:@"Group"];

    // Add the standard properties
    [root addChild:[DDXMLNode elementWithName:@"UUID"
                                  stringValue:[self persistUuid:group.uuid]]];
    [root addChild:[DDXMLNode elementWithName:@"Name"
                                  stringValue:group.name]];
    [root addChild:[DDXMLNode elementWithName:@"Notes"
                                  stringValue:group.notes]];
    [root addChild:[DDXMLNode elementWithName:@"IconID"
                                  stringValue:[NSString stringWithFormat:@"%d", group.image]]];

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
                                  stringValue:[self persistUuid:group.lastTopVisibleEntry]]];

    for (Kdb4Entry *entry in group.entries) {
        [root addChild:[self persistEntry:entry includeHistory:YES]];
    }

    for (Kdb4Group *subGroup in group.groups) {
        [root addChild:[self persistGroup:subGroup]];
    }

    return root;
}

- (DDXMLElement *)persistEntry:(Kdb4Entry *)entry includeHistory:(BOOL)includeHistory {
    DDXMLElement *root = [DDXMLNode elementWithName:@"Entry"];

    // Add the standard properties
    [root addChild:[DDXMLNode elementWithName:@"UUID"
                                  stringValue:[self persistUuid:entry.uuid]]];
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
    [root addChild:[self persistStringField:entry.titleStringField]];
    [root addChild:[self persistStringField:entry.usernameStringField]];
    [root addChild:[self persistStringField:entry.passwordStringField]];
    [root addChild:[self persistStringField:entry.urlStringField]];
    [root addChild:[self persistStringField:entry.notesStringField]];

    // Add the string fields
    for (StringField *stringField in entry.stringFields) {
        [root addChild:[self persistStringField:stringField]];
    }

    // Add the binary references
    for (BinaryRef *binaryRef in entry.binaries) {
        [root addChild:[self persistBinaryRef:binaryRef]];
    }

    // Add the auto-type
    [root addChild:[self persistAutoType:entry.autoType]];

    // Add the history entries
    if (includeHistory) {
        DDXMLElement *historyElement = [DDXMLElement elementWithName:@"History"];
        for (Kdb4Entry *oldEntry in entry.history) {
            [historyElement addChild:[self persistEntry:oldEntry includeHistory:NO]];
        }
        [root addChild:historyElement];
    }

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

- (DDXMLElement *)persistBinaryRef:(BinaryRef *)binaryRef {
    DDXMLElement *root = [DDXMLNode elementWithName:@"Binary"];

    [root addChild:[DDXMLElement elementWithName:@"Key" stringValue:binaryRef.key]];

    DDXMLElement *element = [DDXMLElement elementWithName:@"Value"];
    [element addAttributeWithName:@"Ref" stringValue:[NSString stringWithFormat:@"%d", binaryRef.ref]];
    [root addChild:element];

    return root;
}

- (DDXMLElement *)persistAutoType:(AutoType *)autoType {
    DDXMLElement *root = [DDXMLNode elementWithName:@"AutoType"];

    [root addChild:[DDXMLElement elementWithName:@"Enabled"
                                     stringValue:autoType.enabled ? @"True" : @"False"]];
    [root addChild:[DDXMLElement elementWithName:@"DataTransferObfuscation"
                                     stringValue:[NSString stringWithFormat:@"%d", autoType.dataTransferObfuscation]]];

    // Add the associations
    for (Association *association in autoType.associations) {
        DDXMLElement *element = [DDXMLElement elementWithName:@"Association"];

        [element addChild:[DDXMLElement elementWithName:@"Window" stringValue:association.window]];
        [element addChild:[DDXMLElement elementWithName:@"KeystrokeSequence" stringValue:association.keystrokeSequence]];

        [root addChild:element];
    }

    return root;
}

- (NSString *)persistUuid:(UUID *)uuid {
    NSData *data = [Base64 encode:[uuid getData]];
    return [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
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
