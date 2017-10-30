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

#import "Kdb4Parser.h"
#import "Kdb4Node.h"
#import "DDXML.h"
#import "DDXMLElementAdditions.h"
#import "DDXMLDocument+MKPAdditions.h"
#import "Base64.h"
#import "Utils.h"

@interface Kdb4Parser (PrivateMethods)

- (void)decodeProtected:(DDXMLElement *)root;
- (void)parseMeta:(DDXMLElement *)root;
- (CustomIcon *)parseCustomIcon:(DDXMLElement *)root;
- (Binary *)parseBinary:(DDXMLElement *)root;
- (CustomItem *)parseCustomItem:(DDXMLElement *)root;
- (Kdb4Group *)parseGroup:(DDXMLElement *)root;
- (Kdb4Entry *)parseEntry:(DDXMLElement *)root;
- (BinaryRef *)parseBinaryRef:(DDXMLElement *)root;
- (AutoType *)parseAutoType:(DDXMLElement *)root;
- (KdbUUID *)parseUuidString:(NSString *)uuidString;
- (NSMutableData *)parseBase64String:(NSString *)base64String;
- (DeletedObject *)parseDeletedObject:(DDXMLElement *)root;
- (NSDate *)parseDateTime:(NSString *)dateString;
@end

@implementation Kdb4Parser
NSDate *Kdbx4ReferenceDate;

- (id)initWithRandomStream:(RandomStream *)cryptoRandomStream {
    self = [super init];
    if (self) {
        randomStream = cryptoRandomStream;

        dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.timeZone = [NSTimeZone timeZoneWithName:@"GMT"];
        dateFormatter.dateFormat = @"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'";
        Kdbx4ReferenceDate = [dateFormatter dateFromString:@"0001-01-01T00:00:00Z"];
    }
    return self;
}

int	readCallback(void *context, char *buffer, int len) {
    InputStream *inputStream = (__bridge InputStream*)context;
    return (int)[inputStream read:buffer length:len];
}

int closeCallback(void *context) {
    return 0;
}

- (Kdb4Tree *)parse:(InputStream *)inputStream dbVersion:(uint32_t)dbVer {
    DDXMLDocument *document = [[DDXMLDocument alloc] initWithReadIO:readCallback
                                                             closeIO:closeCallback
                                                             context:(__bridge void *)(inputStream)
                                                             options:0
                                                               error:nil];
    if (document == nil) {
        @throw [NSException exceptionWithName:@"ParseError" reason:@"Failed to parse database" userInfo:nil];
    }
    
    // Get the root document element
    DDXMLElement *rootElement = [document rootElement];

    // Decode all the protected entries
    [self decodeProtected:rootElement];

    tree = [[Kdb4Tree alloc] init];
    tree.dbVersion = dbVer;

    DDXMLElement *meta = [rootElement elementForName:@"Meta"];
    if (meta != nil) {
        [self parseMeta:meta];
    }

    DDXMLElement *root = [rootElement elementForName:@"Root"];
    if (root == nil) {
        @throw [NSException exceptionWithName:@"ParseError" reason:@"Failed to parse database" userInfo:nil];
    }

    DDXMLElement *element = [root elementForName:@"Group"];
    if (element == nil) {
        @throw [NSException exceptionWithName:@"ParseError" reason:@"Failed to parse database" userInfo:nil];
    }

    tree.root = [self parseGroup:element];

    DDXMLElement *deletedObjects = [rootElement elementForName:@"DeletedObjects"];
    for (DDXMLElement *deletedObjectElement in [deletedObjects elementsForName:@"DeletedObject"]) {
        DeletedObject *deletecObject = [self parseDeletedObject:deletedObjectElement];
        [tree.deletedObjects addObject:deletecObject];
    }

    return tree;
}

- (void)decodeProtected:(DDXMLElement *)root {
    DDXMLNode *protectedAttribute = [root attributeForName:@"Protected"];
    if ([[protectedAttribute stringValue] isEqual:@"True"]) {
        NSString *str = [root stringValue];

        // Base64 decode the string
        NSMutableData *data = [self parseBase64String:str];

        // Unprotect the password
        [randomStream xor:data];

        NSString *unprotected = [[NSString alloc] initWithBytes:data.bytes length:data.length encoding:NSUTF8StringEncoding];
        [root setStringValue:unprotected];
    }

    for (DDXMLNode *node in [root children]) {
        if ([node kind] == DDXMLElementKind) {
            [self decodeProtected:(DDXMLElement*)node];
        }
    }
}

- (void)parseMeta:(DDXMLElement *)root {
    tree.generator = [[root elementForName:@"Generator"] stringValue];

    DDXMLElement *headerHashElement = [root elementForName:@"HeaderHash"];
    if (headerHashElement != nil) {
        tree.headerHash = [self parseBase64String:[headerHashElement stringValue]];
    }

    tree.databaseName = [[root elementForName:@"DatabaseName"] stringValue];
    tree.databaseNameChanged = [self parseDateTime:[[root elementForName:@"DatabaseNameChanged"] stringValue]];
    tree.databaseDescription = [[root elementForName:@"DatabaseDescription"] stringValue];
    tree.databaseDescriptionChanged = [self parseDateTime:[[root elementForName:@"DatabaseDescriptionChanged"] stringValue]];
    tree.defaultUserName = [[root elementForName:@"DefaultUserName"] stringValue];
    tree.defaultUserNameChanged = [self parseDateTime:[[root elementForName:@"DefaultUserNameChanged"] stringValue]];
    tree.maintenanceHistoryDays = [[[root elementForName:@"MaintenanceHistoryDays"] stringValue] integerValue];
    tree.color = [[root elementForName:@"Color"] stringValue];
    tree.masterKeyChanged = [self parseDateTime:[[root elementForName:@"MasterKeyChanged"] stringValue]];
    tree.masterKeyChangeRec = [[[root elementForName:@"MasterKeyChangeRec"] stringValue] integerValue];
    tree.masterKeyChangeForce = [[[root elementForName:@"MasterKeyChangeForce"] stringValue] integerValue];

    DDXMLElement *memoryProtectionElement = [root elementForName:@"MemoryProtection"];
    tree.protectTitle = [[[memoryProtectionElement elementForName:@"ProtectTitle"] stringValue] boolValue];
    tree.protectUserName = [[[memoryProtectionElement elementForName:@"ProtectUserName"] stringValue] boolValue];
    tree.protectPassword = [[[memoryProtectionElement elementForName:@"ProtectPassword"] stringValue] boolValue];
    tree.protectUrl = [[[memoryProtectionElement elementForName:@"ProtectURL"] stringValue] boolValue];
    tree.protectNotes = [[[memoryProtectionElement elementForName:@"ProtectNotes"] stringValue] boolValue];

    DDXMLElement *customIconsElement = [root elementForName:@"CustomIcons"];
    for (DDXMLElement *element in [customIconsElement elementsForName:@"Icon"]) {
        [tree.customIcons addObject:[self parseCustomIcon:element]];
    }

    tree.recycleBinEnabled = [[[root elementForName:@"RecycleBinEnabled"] stringValue] boolValue];
    tree.recycleBinUuid = [self parseUuidString:[[root elementForName:@"RecycleBinUUID"] stringValue]];
    tree.recycleBinChanged = [self parseDateTime:[[root elementForName:@"RecycleBinChanged"] stringValue]];
    tree.entryTemplatesGroup = [self parseUuidString:[[root elementForName:@"EntryTemplatesGroup"] stringValue]];
    tree.entryTemplatesGroupChanged = [self parseDateTime:[[root elementForName:@"EntryTemplatesGroupChanged"] stringValue]];
    tree.historyMaxItems = [[[root elementForName:@"HistoryMaxItems"] stringValue] integerValue];
    tree.historyMaxSize = [[[root elementForName:@"HistoryMaxSize"] stringValue] integerValue];
    tree.lastSelectedGroup = [self parseUuidString:[[root elementForName:@"LastSelectedGroup"] stringValue]];
    tree.lastTopVisibleGroup = [self parseUuidString:[[root elementForName:@"LastTopVisibleGroup"] stringValue]];

    DDXMLElement *binariesElement = [root elementForName:@"Binaries"];
    for (DDXMLElement *element in [binariesElement elementsForName:@"Binary"]) {
        [tree.binaries addObject:[self parseBinary:element]];
    }

    DDXMLElement *customDataElement = [root elementForName:@"CustomData"];
    for (DDXMLElement *element in [customDataElement elementsForName:@"Item"]) {
        [tree.customData addObject:[self parseCustomItem:element]];
    }
}

- (CustomIcon *)parseCustomIcon:(DDXMLElement *)root {
    CustomIcon *customIcon = [[CustomIcon alloc] init];

    customIcon.uuid = [self parseUuidString:[[root elementForName:@"UUID"] stringValue]];
    customIcon.data = [[root elementForName:@"Data"] stringValue];

    return customIcon;
}

- (Binary *)parseBinary:(DDXMLElement *)root {
    Binary *binary = [[Binary alloc] init];

    binary.binaryId = [[[root attributeForName:@"ID"] stringValue] integerValue];
    binary.compressed = [[[root attributeForName:@"Compressed"] stringValue] boolValue];
    binary.data = [root stringValue];

    return binary;
}

- (CustomItem *)parseCustomItem:(DDXMLElement *)root {
    CustomItem *customItem = [[CustomItem alloc] init];

    customItem.key = [[root elementForName:@"Key"] stringValue];
    customItem.value = [[root elementForName:@"Value"] stringValue];

    return customItem;
}

- (Kdb4Group *)parseGroup:(DDXMLElement *)root {
    Kdb4Group *group = [[Kdb4Group alloc] init];

    group.uuid = [self parseUuidString:[[root elementForName:@"UUID"] stringValue]];
    if (group.uuid == nil) {
        group.uuid = [KdbUUID uuid];
    }

    group.name = [[root elementForName:@"Name"] stringValue];
    group.notes = [[root elementForName:@"Notes"] stringValue];
    group.image = [[[root elementForName:@"IconID"] stringValue] integerValue];

    DDXMLElement *customIconUuidElement = [root elementForName:@"CustomIconUUID"];
    if (customIconUuidElement != nil) {
        group.customIconUuid = [self parseUuidString:[customIconUuidElement stringValue]];
    }

    DDXMLElement *customDataElement = [root elementForName:@"CustomData"];
    for (DDXMLElement *element in [customDataElement elementsForName:@"Item"]) {
        [group.customData addObject:[self parseCustomItem:element]];
    }

    DDXMLElement *timesElement = [root elementForName:@"Times"];
    group.lastModificationTime = [self parseDateTime:[[timesElement elementForName:@"LastModificationTime"] stringValue]];
    group.creationTime = [self parseDateTime:[[timesElement elementForName:@"CreationTime"] stringValue]];
    group.lastAccessTime = [self parseDateTime:[[timesElement elementForName:@"LastAccessTime"] stringValue]];
    group.expiryTime = [self parseDateTime:[[timesElement elementForName:@"ExpiryTime"] stringValue]];
    group.expires = [[[timesElement elementForName:@"Expires"] stringValue] boolValue];
    group.usageCount = [[[timesElement elementForName:@"UsageCount"] stringValue] integerValue];
    group.locationChanged = [self parseDateTime:[[timesElement elementForName:@"LocationChanged"] stringValue]];

    group.isExpanded = [[[root elementForName:@"IsExpanded"] stringValue] boolValue];
    group.defaultAutoTypeSequence = [[root elementForName:@"DefaultAutoTypeSequence"] stringValue];
    group.enableAutoType = [[root elementForName:@"EnableAutoType"] stringValue];
    group.enableSearching = [[root elementForName:@"EnableSearching"] stringValue];
    group.lastTopVisibleEntry = [self parseUuidString:[[root elementForName:@"LastTopVisibleEntry"] stringValue]];

    for (DDXMLElement *element in [root elementsForName:@"Entry"]) {
        Kdb4Entry *entry = [self parseEntry:element];
        entry.parent = group;

        [group addEntry:entry];
    }

    for (DDXMLElement *element in [root elementsForName:@"Group"]) {
        Kdb4Group *subGroup = [self parseGroup:element];
        subGroup.parent = group;

        [group addGroup:subGroup];
    }

    return group;
}

- (Kdb4Entry *)parseEntry:(DDXMLElement *)root {
    Kdb4Entry *entry = [[Kdb4Entry alloc] init];

    entry.uuid = [self parseUuidString:[[root elementForName:@"UUID"] stringValue]];
    if (entry.uuid == nil) {
        entry.uuid = [KdbUUID uuid];
    }

    entry.image = [[[root elementForName:@"IconID"] stringValue] integerValue];

    DDXMLElement *customIconUuidElement = [root elementForName:@"CustomIconUUID"];
    if (customIconUuidElement != nil) {
        entry.customIconUuid = [self parseUuidString:[customIconUuidElement stringValue]];
    }

    entry.foregroundColor = [[root elementForName:@"ForegroundColor"] stringValue];
    entry.backgroundColor = [[root elementForName:@"BackgroundColor"] stringValue];
    entry.overrideUrl = [[root elementForName:@"OverrideURL"] stringValue];
    entry.tags = [[root elementForName:@"Tags"] stringValue];

    DDXMLElement *timesElement = [root elementForName:@"Times"];
    entry.lastModificationTime = [self parseDateTime:[[timesElement elementForName:@"LastModificationTime"] stringValue]];
    entry.creationTime = [self parseDateTime:[[timesElement elementForName:@"CreationTime"] stringValue]];
    entry.lastAccessTime = [self parseDateTime:[[timesElement elementForName:@"LastAccessTime"] stringValue]];
    entry.expiryTime = [self parseDateTime:[[timesElement elementForName:@"ExpiryTime"] stringValue]];
    entry.expires = [[[timesElement elementForName:@"Expires"] stringValue] boolValue];
    entry.usageCount = [[[timesElement elementForName:@"UsageCount"] stringValue] integerValue];
    entry.locationChanged = [self parseDateTime:[[timesElement elementForName:@"LocationChanged"] stringValue]];

    for (DDXMLElement *element in [root elementsForName:@"String"]) {
        StringField *stringField = [self parseStringField:element];

        if ([stringField.key isEqualToString:FIELD_TITLE]) {
            entry.titleStringField = stringField;
        } else if ([stringField.key isEqualToString:FIELD_USER_NAME]) {
            entry.usernameStringField = stringField;
        } else if ([stringField.key isEqualToString:FIELD_PASSWORD]) {
            entry.passwordStringField = stringField;
        } else if ([stringField.key isEqualToString:FIELD_URL]) {
            entry.urlStringField = stringField;
        } else if ([stringField.key isEqualToString:FIELD_NOTES]) {
            entry.notesStringField = stringField;
        } else {
            [entry.stringFields addObject:stringField];
        }
    }

    for (DDXMLElement *element in [root elementsForName:@"Binary"]) {
        BinaryRef *br = [self parseBinaryRef:element];
        if (br != nil) {
            entry.binaryDict[br.key] = br;
        }
    }

    DDXMLElement *customDataElement = [root elementForName:@"CustomData"];
    for (DDXMLElement *element in [customDataElement elementsForName:@"Item"]) {
        [entry.customData addObject:[self parseCustomItem:element]];
    }

    entry.autoType = [self parseAutoType:[root elementForName:@"AutoType"]];

    DDXMLElement *historyElement = [root elementForName:@"History"];
    if (historyElement != nil) {
        for (DDXMLElement *element in [historyElement elementsForName:@"Entry"]) {
            [entry.history addObject:[self parseEntry:element]];
        }
    }

    return entry;
}

- (StringField *)parseStringField:(DDXMLElement *)root {
    StringField *stringField = [[StringField alloc] init];

    stringField.key = [[root elementForName:@"Key"] stringValue];

    DDXMLElement *valueElement = [root elementForName:@"Value"];
    stringField.value = [valueElement stringValue];
    stringField.protected = [[[valueElement attributeForName:@"Protected"] stringValue] boolValue];

    return stringField;
}

- (BinaryRef *)parseBinaryRef:(DDXMLElement *)root {
    BinaryRef *binaryRef = [[BinaryRef alloc] init];

    binaryRef.key = [[root elementForName:@"Key"] stringValue];
    binaryRef.index = [[[[root elementForName:@"Value"] attributeForName:@"Ref"] stringValue] integerValue];
    
    for (Binary *b in tree.binaries) {
        if (b.binaryId == binaryRef.index) {
            binaryRef.data = b.data;
            return binaryRef;
        }
    }
                                       
    return nil;
}

- (AutoType *)parseAutoType:(DDXMLElement *)root {
    AutoType *autoType = [[AutoType alloc] init];

    autoType.enabled = [[[root elementForName:@"Enabled"] stringValue] boolValue];
    autoType.dataTransferObfuscation = [[[root elementForName:@"DataTransferObfuscation"] stringValue] integerValue];

    DDXMLElement *defaultSequenceElement = [root elementForName:@"DefaultSequence"];
    if (defaultSequenceElement != nil) {
        autoType.defaultSequence = [defaultSequenceElement stringValue];
    }

    for (DDXMLElement *element in [root elementsForName:@"Association"]) {
        Association *association = [[Association alloc] init];

        association.window = [[element elementForName:@"Window"] stringValue];
        association.keystrokeSequence = [[element elementForName:@"KeystrokeSequence"] stringValue];

        [autoType.associations addObject:association];
    }
    
    return autoType;
}

- (NSDate *)parseDateTime:(NSString *)dateString {
    NSDate *date = nil;
    //  KDBX 4 files store dates as base64 encoded seconds since epoch.
    if (tree.dbVersion >= KDBX40_VERSION) {
        NSData *dateBytes = [[NSData alloc] initWithBase64EncodedString:dateString options:NSDataBase64DecodingIgnoreUnknownCharacters];
        uint64_t lSec = [Utils BytesToInt64:dateBytes];
        date = [NSDate dateWithTimeInterval:lSec sinceDate:Kdbx4ReferenceDate];
    } else {
        date = [dateFormatter dateFromString:dateString];
    }
    
    return date;
}


- (KdbUUID *)parseUuidString:(NSString *)uuidString {
    if ([uuidString length] == 0) {
        return nil;
    }

    NSData *data = [self parseBase64String:uuidString];
    return [[KdbUUID alloc] initWithData:data];
}

- (NSMutableData *)parseBase64String:(NSString *)base64String {
    return [Base64 decode:[base64String dataUsingEncoding:NSASCIIStringEncoding]];
}

- (DeletedObject *)parseDeletedObject:(DDXMLElement *)root {
    DeletedObject *deletedObject = [[DeletedObject alloc] init];
    deletedObject.uuid = [self parseUuidString:[[root elementForName:@"UUID"] stringValue]];
    deletedObject.deletionTime = [self parseDateTime:[[root elementForName:@"DeletionTime"] stringValue]];

    return deletedObject;
}

@end
