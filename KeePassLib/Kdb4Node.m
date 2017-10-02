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
        _binaries = [[NSMutableArray alloc] init];
        _history = [[NSMutableArray alloc] init];
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

@end


@implementation Kdb4Tree

- (id)init {
    self = [super init];
    if (self) {
        _rounds = DEFAULT_TRANSFORMATION_ROUNDS;
        _compressionAlgorithm = COMPRESSION_GZIP;
        _customIcons = [[NSMutableArray alloc] init];
        _binaries = [[NSMutableArray alloc] init];
        _customData = [[NSMutableArray alloc] init];
        _deletedObjects = [[NSMutableArray alloc] init];
    }
    return self;
}

- (KdbGroup*)createGroup:(KdbGroup*)parent {
    Kdb4Group *group = [[Kdb4Group alloc] init];

    group.uuid = [UUID uuid];
    group.notes = @"";
    group.image = 0;
    group.isExpanded = true;
    group.defaultAutoTypeSequence = @"";
    group.enableAutoType = @"null";
    group.enableSearching = @"null";
    group.lastTopVisibleEntry = [UUID nullUuid];

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

- (KdbEntry*)createEntry:(KdbGroup*)parent {
    Kdb4Entry *entry = [[Kdb4Entry alloc] init];

    entry.uuid = [UUID uuid];
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

@end
