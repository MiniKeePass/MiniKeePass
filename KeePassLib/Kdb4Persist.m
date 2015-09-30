/*
 * Copyright 2011-2012 Jason Rush and John Flanagan. All rights reserved.
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
- (NSString *)persistBase64Data:(NSData *)data;
- (DDXMLElement *)persistDeletedObject:(DeletedObject *)deletedObject;
- (void)encodeProtected:(DDXMLElement*)root;
@end

@implementation Kdb4Persist

- (id)initWithTree:(Kdb4Tree*)t outputStream:(OutputStream*)stream randomStream:(RandomStream*)cryptoRandomStream {
    self = [super init];
    if (self) {
        tree = t;
        outputStream = stream;
        randomStream = cryptoRandomStream;

        dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.timeZone = [NSTimeZone timeZoneWithName:@"GMT"];
        dateFormatter.dateFormat = @"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'";
    }
    return self;
}

- (void)persist {
    // Update the DOM model
    DDXMLDocument *document = [self persistTree];

    // Encode all the protected entries
    [self encodeProtected:document.rootElement];

    // Serialize the DOM to XML
    [outputStream write:[document XMLDataWithOptions:DDXMLNodeCompactEmptyElement]];
}

- (DDXMLDocument *)persistTree {
    DDXMLElement *element;

    DDXMLDocument *document = [[DDXMLDocument alloc] initWithXMLString:@"<KeePassFile></KeePassFile>" options:0 error:nil];

    element = [DDXMLNode elementWithName:@"Meta"];
    [element addChild:[DDXMLNode elementWithName:@"Generator"
                                     stringValue:tree.generator]];
    [element addChild:[DDXMLNode elementWithName:@"HeaderHash"
                                    stringValue:[self persistBase64Data:tree.headerHash]]];
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
                                     stringValue:[NSString stringWithFormat:@"%ld", (long)tree.maintenanceHistoryDays]]];
    [element addChild:[DDXMLNode elementWithName:@"Color"
                                     stringValue:tree.color]];
    [element addChild:[DDXMLNode elementWithName:@"MasterKeyChanged"
                                     stringValue:[dateFormatter stringFromDate:tree.masterKeyChanged]]];
    [element addChild:[DDXMLNode elementWithName:@"MasterKeyChangeRec"
                                     stringValue:[NSString stringWithFormat:@"%ld", (long)tree.masterKeyChangeRec]]];
    [element addChild:[DDXMLNode elementWithName:@"MasterKeyChangeForce"
                                     stringValue:[NSString stringWithFormat:@"%ld", (long)tree.masterKeyChangeForce]]];

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

    if ([tree.customIcons count] > 0) {
        DDXMLElement *customIconsElements = [DDXMLElement elementWithName:@"CustomIcons"];
        for (CustomIcon *customIcon in tree.customIcons) {
            [customIconsElements addChild:[self persistCustomIcon:customIcon]];
        }
        [element addChild:customIconsElements];
    }

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
                                     stringValue:[NSString stringWithFormat:@"%ld", (long)tree.historyMaxItems]]];
    [element addChild:[DDXMLNode elementWithName:@"HistoryMaxSize"
                                     stringValue:[NSString stringWithFormat:@"%ld", (long)tree.historyMaxSize]]];
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

    DDXMLElement *deletedObjectsElement = [DDXMLElement elementWithName:@"DeletedObjects"];
    for (DeletedObject *deletedObject in tree.deletedObjects) {
        [deletedObjectsElement addChild:[self persistDeletedObject:deletedObject]];
    }
    [element addChild:deletedObjectsElement];

    [document.rootElement addChild:element];

    return document;
}

- (DDXMLElement *)persistCustomIcon:(CustomIcon *)customIcon {
    DDXMLElement *root = [DDXMLNode elementWithName:@"Icon"];

    [root addChild:[DDXMLNode elementWithName:@"UUID" stringValue:[self persistUuid:customIcon.uuid]]];
    [root addChild:[DDXMLNode elementWithName:@"Data" stringValue:customIcon.data]];

    return root;
}

- (DDXMLElement *)persistBinary:(Binary *)binary {
    DDXMLElement *root = [DDXMLNode elementWithName:@"Binary"];

    [root addAttributeWithName:@"ID" stringValue:[NSString stringWithFormat:@"%ld", (long)binary.binaryId]];
    [root addAttributeWithName:@"Compressed" stringValue:binary.compressed ? @"True" : @"False"];
    root.stringValue = binary.data;

    return root;
}

- (DDXMLElement *)persistCustomItem:(CustomItem *)customItem {
    DDXMLElement *root = [DDXMLNode elementWithName:@"Item"];

    [root addChild:[DDXMLNode elementWithName:@"Key"
                                  stringValue:customItem.key]];
    [root addChild:[DDXMLNode elementWithName:@"Value"
                                  stringValue:customItem.value]];

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
                                  stringValue:[NSString stringWithFormat:@"%ld", (long)group.image]]];
    if (group.customIconUuid != nil) {
        [root addChild:[DDXMLNode elementWithName:@"CustomIconUUID"
                                      stringValue:[self persistUuid:group.customIconUuid]]];
    }

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
                                          stringValue:[NSString stringWithFormat:@"%ld", (long)group.usageCount]]];
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
                                  stringValue:[NSString stringWithFormat:@"%ld", (long)entry.image]]];
    if (entry.customIconUuid != nil) {
        [root addChild:[DDXMLNode elementWithName:@"CustomIconUUID"
                                      stringValue:[self persistUuid:entry.customIconUuid]]];
    }
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
                                          stringValue:[NSString stringWithFormat:@"%ld", (long)entry.usageCount]]];
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

- (DDXMLElement *)persistStringField:(StringField *)stringField {
    DDXMLElement *root = [DDXMLNode elementWithName:@"String"];

    [root addChild:[DDXMLElement elementWithName:@"Key" stringValue:stringField.key]];

    DDXMLElement *element = [DDXMLElement elementWithName:@"Value" stringValue:stringField.value];
    if (stringField.protected) {
        [element addAttributeWithName:@"Protected" stringValue:@"True"];
    }
    [root addChild:element];

    return root;
}

- (DDXMLElement *)persistBinaryRef:(BinaryRef *)binaryRef {
    DDXMLElement *root = [DDXMLNode elementWithName:@"Binary"];

    [root addChild:[DDXMLElement elementWithName:@"Key" stringValue:binaryRef.key]];

    DDXMLElement *element = [DDXMLElement elementWithName:@"Value"];
    [element addAttributeWithName:@"Ref" stringValue:[NSString stringWithFormat:@"%ld", (long)binaryRef.ref]];
    [root addChild:element];

    return root;
}

- (DDXMLElement *)persistAutoType:(AutoType *)autoType {
    DDXMLElement *root = [DDXMLNode elementWithName:@"AutoType"];

    [root addChild:[DDXMLElement elementWithName:@"Enabled"
                                     stringValue:autoType.enabled ? @"True" : @"False"]];
    [root addChild:[DDXMLElement elementWithName:@"DataTransferObfuscation"
                                     stringValue:[NSString stringWithFormat:@"%ld", (long)autoType.dataTransferObfuscation]]];

    if (autoType.defaultSequence != nil) {
        [root addChild:[DDXMLElement elementWithName:@"DefaultSequence" stringValue:autoType.defaultSequence]];
    }

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
    NSData *data = [uuid getData];
    return [self persistBase64Data:data];
}

- (NSString *)persistBase64Data:(NSData *)data {
    NSData *encodedData = [Base64 encode:data];
    return [[NSString alloc] initWithData:encodedData encoding:NSASCIIStringEncoding];
}

- (DDXMLElement *)persistDeletedObject:(DeletedObject *)deletedObject {
    DDXMLElement *element = [DDXMLElement elementWithName:@"DeletedObject"];

    [element addChild:[DDXMLElement elementWithName:@"UUID"
                                        stringValue:[self persistUuid:deletedObject.uuid]]];
    [element addChild:[DDXMLElement elementWithName:@"DeletionTime"
                                        stringValue:[dateFormatter stringFromDate:deletedObject.deletionTime]]];

    return element;
}


- (void)encodeProtected:(DDXMLElement*)root {
    DDXMLNode *protectedAttribute = [root attributeForName:@"Protected"];
    if ([[protectedAttribute stringValue] isEqual:@"True"]) {
        NSString *str = [root stringValue];
        NSMutableData *mutableData = [[str dataUsingEncoding:NSUTF8StringEncoding] mutableCopy];

        // Unprotect the password
        [randomStream xor:mutableData];

        // Base64 encode the string
        NSString *protected = [self persistBase64Data:mutableData];

        [root setStringValue:protected];
    }
    
    for (DDXMLNode *node in [root children]) {
        if ([node kind] == DDXMLElementKind) {
            [self encodeProtected:(DDXMLElement*)node];
        }
    }
}

@end
