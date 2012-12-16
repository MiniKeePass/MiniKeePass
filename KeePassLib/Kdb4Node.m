//
//  Kdb4Node.m
//  KeePass2
//
//  Created by Qiang Yu on 2/23/10.
//  Copyright 2010 Qiang Yu. All rights reserved.
//

#import "Kdb4Node.h"

@implementation Kdb4Group

- (void)dealloc {
    [_uuid release];
    [_notes release];
    [_defaultAutoTypeSequence release];
    [_enableAutoType release];
    [_enableSearching release];
    [_lastTopVisibleEntry release];
    [_locationChanged release];
    [super dealloc];
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
    return [[[StringField alloc] initWithKey:key andValue:value] autorelease];
}

- (void)dealloc {
    [_key release];
    [_value release];
    [super dealloc];
}

- (id)copyWithZone:(NSZone *)zone {
    return [[StringField alloc] initWithKey:self.key andValue:self.value andProtected:self.protected];
}

@end


@implementation CustomIcon

- (void)dealloc {
    [_uuid release];
    [_data release];
    [super dealloc];
}

@end


@implementation CustomItem

- (void)dealloc {
    [_key release];
    [_value release];
    [super dealloc];
}

@end


@implementation Binary

- (void)dealloc {
    [_data release];
    [super dealloc];
}

@end


@implementation BinaryRef

- (void)dealloc {
    [_key release];
    [super dealloc];
}

@end


@implementation Association

- (void)dealloc {
    [_window release];
    [_keystrokeSequence release];
    [super dealloc];
}

@end


@implementation AutoType

- (id)init {
    self = [super init];
    if (self) {
        _associations = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)dealloc {
    [_defaultSequence release];
    [_associations release];
    [super dealloc];
}

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

- (void)dealloc {
    [_uuid release];
    [_titleStringField release];
    [_usernameStringField release];
    [_passwordStringField release];
    [_urlStringField release];
    [_notesStringField release];
    [_customIconUuid release];
    [_foregroundColor release];
    [_backgroundColor release];
    [_overrideUrl release];
    [_tags release];
    [_locationChanged release];
    [_stringFields release];
    [_binaries release];
    [_autoType release];
    [_history release];
    [super dealloc];
}

- (NSString *)title {
    return _titleStringField.value;
}

- (void)setTitle:(NSString *)title {
    _titleStringField.value = title;
}

- (NSString *)username {
    return _usernameStringField.value;
}

- (void)setUsername:(NSString *)username {
    _usernameStringField.value = username;
}

- (NSString *)password {
    return _passwordStringField.value;
}

- (void)setPassword:(NSString *)password {
    _passwordStringField.value = password;
}

- (NSString *)url {
    return _urlStringField.value;
}

- (void)setUrl:(NSString *)url {
    _urlStringField.value = url;
}

- (NSString *)notes {
    return _notesStringField.value;
}

- (void)setNotes:(NSString *)notes {
    _notesStringField.value = notes;
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
    }
    return self;
}

- (void)dealloc {
    [_generator release];
    [_databaseName release];
    [_databaseNameChanged release];
    [_databaseDescription release];
    [_databaseDescriptionChanged release];
    [_defaultUserName release];
    [_defaultUserNameChanged release];
    [_color release];
    [_masterKeyChanged release];
    [_customIcons release];
    [_recycleBinUuid release];
    [_recycleBinChanged release];
    [_entryTemplatesGroup release];
    [_entryTemplatesGroupChanged release];
    [_lastSelectedGroup release];
    [_lastTopVisibleGroup release];
    [_binaries release];
    [_customData release];
    [super dealloc];
}

- (KdbGroup*)createGroup:(KdbGroup*)parent {
    Kdb4Group *group = [[Kdb4Group alloc] init];

    group.uuid = [UUID uuid];
    group.Notes = @"";
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

    return [group autorelease];
}

- (KdbEntry*)createEntry:(KdbGroup*)parent {
    Kdb4Entry *entry = [[Kdb4Entry alloc] init];

    entry.uuid = [UUID uuid];
    entry.image = 0;
    entry.titleStringField = [[[StringField alloc] initWithKey:FIELD_TITLE andValue:@"New Entry"] autorelease];
    entry.usernameStringField = [[[StringField alloc] initWithKey:FIELD_USER_NAME andValue:@""] autorelease];
    entry.passwordStringField = [[[StringField alloc] initWithKey:FIELD_PASSWORD andValue:@"" andProtected:YES] autorelease];
    entry.urlStringField = [[[StringField alloc] initWithKey:FIELD_URL andValue:@""] autorelease];
    entry.notesStringField = [[[StringField alloc] initWithKey:FIELD_NOTES andValue:@""] autorelease];
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
    entry.autoType = [[[AutoType alloc] init] autorelease];
    entry.autoType.enabled = YES;
    entry.autoType.dataTransferObfuscation = 1;

    Association *association = [[[Association alloc] init] autorelease];
    association.window = @"Target Window";
    association.keystrokeSequence = @"{USERNAME}{TAB}{PASSWORD}{TAB}{ENTER}";
    [entry.autoType.associations addObject:association];

    return [entry autorelease];
}

@end
