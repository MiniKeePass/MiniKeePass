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

#import "Kdb4Node.h"

@implementation Kdb4Group
- (id)init {
    self = [super init];
    if (self) {
        _customData = [[NSMutableArray alloc] init];
    }
    return self;
}

- (Kdb4Group*)findGroup:(KdbUUID *)uuid {
    if ([self.uuid isEqual:uuid]) return self;
    
    for (KdbGroup *g in self.groups) {
        Kdb4Group *group = (Kdb4Group*)g;
        Kdb4Group *subGroup = [group findGroup:uuid];
        if (subGroup != nil) return subGroup;
    }
    
    return nil;
}

@end

@implementation StringField

- (id)initWithKey:(NSString *)key andValue:(NSString *)value {
    return [self initWithKey:key andValue:value andProtected:NO];
}

- (id)initWithKey:(NSString *)key andValue:(NSString *)value andProtected:(BOOL)protected {
    self = [super init];
    if (self) {
        _key = [key copy];
        _value = [value copy];
        _protected = protected;
    }
    return self;
}

+ (id)stringFieldWithKey:(NSString *)key andValue:(NSString *)value {
    return [[StringField alloc] initWithKey:key andValue:value];
}

- (id)copyWithZone:(NSZone *)zone {
    return [[StringField alloc] initWithKey:self.key andValue:self.value andProtected:self.protected];
}

- (BOOL)contentsEqual:(StringField *)sf {
    BOOL contentsEqual = false;
    
    contentsEqual = [self.key isEqualToString:sf.key];
    contentsEqual &= [self.value isEqualToString:sf.value];
    contentsEqual &= self.protected == sf.protected;
    
    return contentsEqual;
}

@end

@implementation CustomIcon
@end

@implementation CustomItem
@end

@implementation Binary
@end

@implementation BinaryRef
@end

@implementation Association
@end

@implementation AutoType

- (id)init {
    self = [super init];
    if (self) {
        _associations = [[NSMutableArray alloc] init];
    }
    return self;
}

@end

@implementation DeletedObject
@end

@implementation Kdb4Entry

- (id)init {
    self = [super init];
    if (self) {
        _stringFields = [[NSMutableArray alloc] init];
        _binaryDict = [[NSMutableDictionary alloc] init];
        _history = [[NSMutableArray alloc] init];
        _customData = [[NSMutableArray alloc] init];
    }
    return self;
}

- (NSString *)title {
    if (_titleStringField == nil) {
        return @"";
    }
    return _titleStringField.value;
}

- (void)setTitle:(NSString *)title {
    if (_titleStringField == nil) {
        _titleStringField = [[StringField alloc] initWithKey:FIELD_TITLE andValue:title];
    } else {
        _titleStringField.value = title;
    }
}

- (NSString *)username {
    if (_usernameStringField == nil) {
        return @"";
    }
    return _usernameStringField.value;
}

- (void)setUsername:(NSString *)username {
    if (_usernameStringField == nil) {
        _usernameStringField = [[StringField alloc] initWithKey:FIELD_USER_NAME andValue:username];
    } else {
        _usernameStringField.value = username;
    }
}

- (NSString *)password {
    if (_passwordStringField == nil) {
        return @"";
    }
    return _passwordStringField.value;
}

- (void)setPassword:(NSString *)password {
    if (_passwordStringField == nil) {
        _passwordStringField = [[StringField alloc] initWithKey:FIELD_PASSWORD andValue:password andProtected:YES];
    } else {
        _passwordStringField.value = password;
    }
}

- (NSString *)url {
    if (_urlStringField == nil) {
        return @"";
    }
    return _urlStringField.value;
}

- (void)setUrl:(NSString *)url {
    if (_urlStringField == nil) {
        _urlStringField = [[StringField alloc] initWithKey:FIELD_URL andValue:url];
    } else {
        _urlStringField.value = url;
    }
}

- (NSString *)notes {
    if (_notesStringField == nil) {
        return @"";
    }
    return _notesStringField.value;
}

- (void)setNotes:(NSString *)notes {
    if (_notesStringField == nil) {
        _notesStringField = [[StringField alloc] initWithKey:FIELD_NOTES andValue:notes];
    } else {
        _notesStringField.value = notes;
    }
}

- (Kdb4Entry*)deepCopy {
    Kdb4Entry *entry = [[Kdb4Entry alloc] init];
    
    // Don't copy the history, just the entry itself.
    entry.image = self.image;
    entry.creationTime = self.creationTime;
    entry.lastModificationTime = self.lastModificationTime;
    entry.lastAccessTime = self.lastAccessTime;
    entry.expiryTime = self.expiryTime;

    entry.uuid = self.uuid;  // Shallow copy OK
    entry.titleStringField = [self.titleStringField copy];
    entry.usernameStringField = [self.usernameStringField copy];
    entry.passwordStringField = [self.passwordStringField copy];
    entry.urlStringField = [self.urlStringField copy];
    entry.notesStringField = [self.notesStringField copy];
    entry.customIconUuid = [self.customIconUuid copy];
    entry.foregroundColor = self.foregroundColor;
    entry.backgroundColor = self.backgroundColor;
    entry.overrideUrl = self.overrideUrl;
    entry.tags = self.tags;
    entry.expires = self.expires;
    entry.usageCount = self.usageCount;
    entry.locationChanged = self.locationChanged;
    
    for (StringField *f in self.stringFields) {
        [entry.stringFields addObject:[f copy]];
    }
    
    for (NSString *key in self.binaryDict) {
        BinaryRef *br = self.binaryDict[key];
        BinaryRef *brcopy = [[BinaryRef alloc] init];
        brcopy.key = [br.key copy];
        brcopy.index = br.index;
        brcopy.data = br.data; // shallow copy.
        entry.binaryDict[brcopy.key] = brcopy;
    }
    
    // Handle AutoType
    entry.autoType = [[AutoType alloc] init];
    entry.autoType.enabled = self.autoType.enabled;
    entry.autoType.dataTransferObfuscation = self.autoType.dataTransferObfuscation;
    entry.autoType.defaultSequence = [self.autoType.defaultSequence copy];
    for (Association *a in self.autoType.associations) {
        Association *acopy = [[Association alloc] init];
        acopy.window = [a.window copy];
        acopy.keystrokeSequence = [a.keystrokeSequence copy];
        [entry.autoType.associations addObject:acopy];
    }

    return entry;
}

- (BOOL)hasChanged:(Kdb4Entry*)entry {
    BOOL isEqual = ![super hasChanged:entry];
    
    if (!isEqual) return YES;

    isEqual = [entry.titleStringField contentsEqual:self.titleStringField];
    isEqual &= [entry.usernameStringField contentsEqual:self.usernameStringField];
    isEqual &= [entry.passwordStringField contentsEqual:self.passwordStringField];
    isEqual &= [entry.urlStringField contentsEqual:self.urlStringField];
    isEqual &= [entry.notesStringField contentsEqual:self.notesStringField];
    if (!isEqual) return YES;
    
    if (entry.stringFields.count != self.stringFields.count) return YES;
    for (int i=0; i<self.stringFields.count; ++i) {
        isEqual &= [self.stringFields[i] contentsEqual:entry.stringFields[i]];
    }
    if (!isEqual) return YES;
    
    isEqual &= [entry.overrideUrl isEqualToString:self.overrideUrl];

    // No way to change the following within MiniKeePass so we don't check.
    // customIconUuid
    // foregroundColor;
    // backgroundColor;
    // binaries
    // autoType
    
    return !isEqual;
}

- (void)removeOldestBackup {
    Kdb4Entry *oldestEntry;
    
    if (self.history.count == 0) return;
    
    oldestEntry = self.history[0];
    
    for (Kdb4Entry *e in self.history) {
        if ([e.lastModificationTime compare:oldestEntry.lastModificationTime] == NSOrderedAscending) {
            oldestEntry = e;
        }
    }
    
    [self.history removeObject:oldestEntry];
}

- (NSInteger)getSize {
    NSInteger size = 128;  // Fixed data size approx.
    
    size += self.titleStringField.value.length;
    size += self.titleStringField.key.length;
    size += self.usernameStringField.value.length;
    size += self.usernameStringField.key.length;
    size += self.passwordStringField.value.length;
    size += self.passwordStringField.key.length;
    size += self.urlStringField.value.length;
    size += self.urlStringField.key.length;
    size += self.notesStringField.value.length;
    size += self.notesStringField.key.length;
    
    for (StringField *f in self.stringFields) {
        size += f.value.length;
        size += f.key.length;
    }
    
    for (NSString *key in self.binaryDict) {
        BinaryRef *br = self.binaryDict[key];
        size += br.key.length;
        size += br.data.length;
    }
    
    // Handle AutoType Here.
    size += self.autoType.defaultSequence.length;
    for (Association *a in self.autoType.associations) {
        size += a.window.length;
        size += a.keystrokeSequence.length;
    }

    return size;
}

@end


@implementation Kdb4Tree

- (id)init {
    self = [super init];
    if (self) {
        _compressionAlgorithm = COMPRESSION_GZIP;
        _customIcons = [[NSMutableArray alloc] init];
        _binaries = [[NSMutableArray alloc] init];
        _customData = [[NSMutableArray alloc] init];
        _deletedObjects = [[NSMutableArray alloc] init];
        _forcedVersion = 0;

        _kdfParams = [[VariantDictionary alloc] init];
        _customPluginData = [[VariantDictionary alloc] init];
        _headerBinaries = [[NSMutableArray alloc] init];
    }
    return self;
}

- (KdbGroup*)createGroup:(KdbGroup*)parent {
    Kdb4Group *group = [[Kdb4Group alloc] init];

    group.uuid = [KdbUUID uuid];
    group.notes = @"";
    group.image = 0;
    group.isExpanded = true;
    group.defaultAutoTypeSequence = @"";
    group.enableAutoType = @"null";
    group.enableSearching = @"null";
    group.lastTopVisibleEntry = [KdbUUID nullUuid];

    NSDate *currentTime = [NSDate date];
    group.lastModificationTime = currentTime;
    group.creationTime = currentTime;
    group.lastAccessTime = currentTime;
    group.expiryTime = currentTime;
    group.expires = false;
    group.usageCount = 0;
    group.locationChanged = currentTime;

    return group;
}

- (void)removeGroup:(KdbGroup *)group {
    Kdb4Group *g4 = (Kdb4Group *)group;
    Kdb4Group *parent = nil;

    // Get the recycle bin group.
    Kdb4Group *recycleBin = [self ensureRecycleBin];
    if (recycleBin != nil) {
        // returns non-nil if this group is in the recycle bin or is the recycle bin itself
        parent = [recycleBin findGroup:g4.uuid];
    }

    [super removeGroup:group];
    
    if (recycleBin == nil) return;
    
    // If this is not the recycleBin group and it is not an item in the recycleBin
    // then add to the recycleBin.
    if (parent == nil) {
        g4.locationChanged = [NSDate date];
        [recycleBin addGroup:group];
    }
}


- (KdbEntry*)createEntry:(KdbGroup*)parent {
    Kdb4Entry *entry = [[Kdb4Entry alloc] init];

    entry.uuid = [KdbUUID uuid];
    entry.image = 0;
    entry.titleStringField = [[StringField alloc] initWithKey:FIELD_TITLE andValue:@"New Entry"];
    entry.usernameStringField = [[StringField alloc] initWithKey:FIELD_USER_NAME andValue:@""];
    entry.passwordStringField = [[StringField alloc] initWithKey:FIELD_PASSWORD andValue:@"" andProtected:YES];
    entry.urlStringField = [[StringField alloc] initWithKey:FIELD_URL andValue:@""];
    entry.notesStringField = [[StringField alloc] initWithKey:FIELD_NOTES andValue:@""];
    entry.foregroundColor = @"";
    entry.backgroundColor = @"";
    entry.overrideUrl = @"";
    entry.tags = @"";

    NSDate *currentTime = [NSDate date];
    entry.lastModificationTime = currentTime;
    entry.creationTime = currentTime;
    entry.lastAccessTime = currentTime;
    entry.expiryTime = currentTime;
    entry.expires = false;
    entry.usageCount = 0;
    entry.locationChanged = currentTime;

    // Add a default AutoType object
    entry.autoType = [[AutoType alloc] init];
    entry.autoType.enabled = YES;
    entry.autoType.dataTransferObfuscation = 1;

    Association *association = [[Association alloc] init];
    association.window = @"Target Window";
    association.keystrokeSequence = @"{USERNAME}{TAB}{PASSWORD}{TAB}{ENTER}";
    [entry.autoType.associations addObject:association];

    return entry;
}

- (void)removeEntry:(KdbEntry *)entry {
    Kdb4Group *parent = nil;

    // Get the recycle bin group.
    Kdb4Group *recycleBin = [self ensureRecycleBin];
    if (recycleBin != nil) {
        // returns non-nil if this group is in the recycle bin or is the recycle bin itself
        parent = [recycleBin findGroup:((Kdb4Group *)entry.parent).uuid];
    }
    
    [super removeEntry:entry];

    if (recycleBin == nil) return;
    
    // If this is not the recycleBin group and it is not an item in the recycleBin
    // then add to the recycleBin.
    if (parent == nil) {
        ((Kdb4Entry*)entry).locationChanged = [NSDate date];
        [recycleBin addEntry:entry];
    }
}

- (void)createEntryBackup:(Kdb4Entry*)entry backupEntry:(Kdb4Entry*)backupEntry {
    backupEntry.lastModificationTime = [NSDate date];
    [entry.history addObject:backupEntry];
    
    while (entry.history.count > self.historyMaxItems) {
        [entry removeOldestBackup];
    }
    
    // FIXME find the history size and delete entries if too large.
}


- (Kdb4Group *)ensureRecycleBin {
    if (!self.recycleBinEnabled) {
        return nil;
    }

    Kdb4Group *recycleBin = [(Kdb4Group*)self.root findGroup:self.recycleBinUuid];
    if (recycleBin == nil) {
        // Create the recycle bin.
        recycleBin = (Kdb4Group*)[self createGroup:self.root];
        if (recycleBin == nil) return nil;
        self.recycleBinUuid = recycleBin.uuid;
        recycleBin.image = 43;  // Trash Can
        recycleBin.name = @"Recycle Bin";
        recycleBin.enableSearching = @"false";
        [self.root addGroup:recycleBin];
    }
    
    return recycleBin;
}

@end
