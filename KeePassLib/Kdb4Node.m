//
//  Kdb4Node.m
//  KeePass2
//
//  Created by Qiang Yu on 2/23/10.
//  Copyright 2010 Qiang Yu. All rights reserved.
//

#import "Kdb4Node.h"
#import "DDXMLElement+MKPAdditions.h"

@implementation Kdb4Group

- (id)init {
    self = [super init];
    if (self) {
        _properties = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)dealloc {
    [_properties release];
    [super dealloc];
}

@end


@implementation StringField

- (id)initWithKey:(NSString *)key andValue:(NSString *)value {
    self = [super init];
    if (self) {
        _key = key;
        _value = value;
        _protected = false;
    }
    return self;
}

- (void)dealloc {
    [_key release];
    [_value release];
    [super dealloc];
}

@end


@implementation Kdb4Entry

- (id)init:(DDXMLElement*)e {
    self = [super init];
    if (self) {
        _properties = [[NSMutableDictionary alloc] init];
        _stringFields = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)dealloc {
    [_properties release];
    [_stringFields release];
    [super dealloc];
}

@end


@implementation Kdb4Tree

- (id)initWithDocument:(DDXMLDocument*)doc {
    self = [super init];
    if (self) {
        _properties = [[NSMutableDictionary alloc] init];
        _rounds = DEFAULT_TRANSFORMATION_ROUNDS;
        _compressionAlgorithm = COMPRESSION_GZIP;
    }
    return self;
}

- (void)dealloc {
    [_properties release];
    [super dealloc];
}

- (KdbGroup*)createGroup:(KdbGroup*)parent {
    Kdb4Group *group = [[Kdb4Group alloc] init];

    [group.properties setValue:@"" forKey:@"UUID"]; // FIXME
    [group.properties setValue:@"" forKey:@"Notes"];
    [group.properties setValue:@"0" forKey:@"IconID"];
    [group.properties setValue:@"True" forKey:@"IsExpanded"];
    [group.properties setValue:@"" forKey:@"DefaultAutoTypeSequence"];
    [group.properties setValue:@"null" forKey:@"EnableAutoType"];
    [group.properties setValue:@"null" forKey:@"EnableSearching"];
    [group.properties setValue:@"" forKey:@"LastTopVisibleEntry"];

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

    [entry.properties setValue:@"" forKey:@"UUID"];
    [entry.properties setValue:@"0" forKey:@"IconID"];
    [entry.properties setValue:nil forKey:@"ForegroundColor"];
    [entry.properties setValue:nil forKey:@"BackgroundColor"];
    [entry.properties setValue:nil forKey:@"OverrideURL"];
    [entry.properties setValue:nil forKey:@"Tags"];
    [entry.properties setValue:@"" forKey:@"LastTopVisibleEntry"];
    [entry.properties setValue:nil forKey:@"AutoType"]; // FIXME  Association.Window = Target Window, Association.KeystrokeSequence = {USERNAME}{TAB}{PASSWORD}{TAB}{ENTER}
    [entry.properties setValue:nil forKey:@"History"];

    NSDate *currentTime = [NSDate date];
    entry.lastModificationTime = currentTime;
    entry.creationTime = currentTime;
    entry.lastAccessTime = currentTime;
    entry.expiryTime = currentTime;
    entry.expires = false;
    entry.usageCount = 0;
    entry.locationChanged = currentTime;

    return [entry autorelease];
}

@end
