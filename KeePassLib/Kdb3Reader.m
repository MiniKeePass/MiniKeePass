//
//   Kdb3.m
//   KeePass
//
//   Created by Qiang Yu on 11/22/09.
//   Copyright 2009 Qiang Yu. All rights reserved.
//

#import "Kdb3Reader.h"
#import "AesInputStream.h"
#import "TwoFishInputStream.h"
#import "KdbPassword.h"
#import "Kdb3Node.h"
#import "Kdb3Date.h"
#import "Kdb3Utils.h"

@interface Kdb3Reader (privateMethods)
- (void)readHeader:(InputStream *)inputStream;
- (NSData *)hashHeader:(kdb3_header_t *)header;
- (void)readGroups:(InputStream *)inputStream;
- (void)readEntries:(InputStream*)inputStream;
- (void)readExtData:(InputStream*)inputStream;
- (Kdb3Tree*)buildTree;
@end

@implementation Kdb3Reader

- (id)init {
    self = [super init];
    if (self) {
        masterSeed = nil;
        encryptionIv = nil;
        numGroups = 0;
        numEntries = 0;
        contentsHash = nil;
        masterSeed2 = nil;
        keyEncRounds = 0;
        headerFlags = 0;
        headerHash = nil;
        levels = nil;
        groups = nil;
        entries = nil;
    }
    return self;
}

- (KdbTree*)load:(InputStream *)inputStream withPassword:(KdbPassword *)kdbPassword {
    [self readHeader:inputStream];

    // Create the final key and initialize the AES input stream
    NSData *key = [kdbPassword createFinalKeyForVersion:3 masterSeed:masterSeed transformSeed:masterSeed2 rounds:keyEncRounds];
    
    InputStream *decrpytStream;
    if (headerFlags & FLAG_RIJNDAEL) {
        decrpytStream = [[AesInputStream alloc] initWithInputStream:inputStream key:key iv:encryptionIv];
    } else if (headerFlags & FLAG_TWOFISH) {
        decrpytStream = [[TwoFishInputStream alloc] initWithInputStream:inputStream key:key iv:encryptionIv];
    }
    
    levels = [[NSMutableArray alloc] initWithCapacity:numGroups];
    groups = [[NSMutableArray alloc] initWithCapacity:numGroups];
    entries = [[NSMutableArray alloc] initWithCapacity:numEntries];

    @try {
        // Parse groups
        [self readGroups:decrpytStream];

        // Parse entries
        [self readEntries:decrpytStream];

        // Build the tree
        return [self buildTree];
    } @finally {
        decrpytStream = nil;
    }

    return nil;
}

- (void)readHeader:(InputStream *)inputStream  {
    kdb3_header_t header;

    // Read in the header
    if ([inputStream read:&header length:sizeof(header)] != sizeof(header)) {
        @throw [NSException exceptionWithName:@"IOException" reason:@"Failed to read header" userInfo:nil];
    }

    // Check the signature
    header.signature1 = CFSwapInt32LittleToHost(header.signature1);
    header.signature2 = CFSwapInt32LittleToHost(header.signature2);
    if (!(header.signature1 == KDB3_SIG1 && header.signature2 == KDB3_SIG2)) {
        @throw [NSException exceptionWithName:@"IOException" reason:@"Invalid signature" userInfo:nil];
    }

    // Check the version
    header.version = CFSwapInt32LittleToHost(header.version);
    if ((header.version & 0xFFFFFF00) != (KDB3_VER & 0xFFFFFF00)) {
        @throw [NSException exceptionWithName:@"IOException" reason:@"Unsupported version" userInfo:nil];
    }

    // Check the encryption algorithm
    header.flags = CFSwapInt32LittleToHost(header.flags);
    headerFlags = header.flags;
    if (!(header.flags & FLAG_RIJNDAEL) && !(header.flags & FLAG_TWOFISH)) {
        @throw [NSException exceptionWithName:@"IOException" reason:@"Unsupported algorithm" userInfo:nil];
    }

    masterSeed = [[NSData alloc] initWithBytes:header.masterSeed length:sizeof(header.masterSeed)];
    encryptionIv = [[NSData alloc] initWithBytes:header.encryptionIv length:sizeof(header.encryptionIv)];

    numGroups = CFSwapInt32LittleToHost(header.groups);
    numEntries = CFSwapInt32LittleToHost(header.entries);

    contentsHash = [[NSData alloc] initWithBytes:header.contentsHash length:sizeof(header.contentsHash)];
    masterSeed2 = [[NSData alloc] initWithBytes:header.masterSeed2 length:sizeof(header.masterSeed2)];

    keyEncRounds = CFSwapInt32LittleToHost(header.keyEncRounds);

    // Compute a sha256 hash of the header up to but not including the contentsHash
    headerHash = [Kdb3Utils hashHeader:&header];
}

- (void)readGroups:(InputStream *)inputStream {
    uint16_t fieldType;
    uint32_t fieldSize;
    uint8_t dateBuffer[5];
    uint32_t image = 0;
    BOOL eos;

    // Parse the groups
    for (uint32_t i = 0; i < numGroups; i++) {
        Kdb3Group *group = [[Kdb3Group alloc] init];

        // Parse the fields
        eos = NO;
        while (!eos) {
            fieldType = [inputStream readInt16];
            fieldType = CFSwapInt16LittleToHost(fieldType);

            fieldSize = [inputStream readInt32];
            fieldSize = CFSwapInt32LittleToHost(fieldSize);

            switch (fieldType) {
                case 0x0000:
                    if (fieldSize > 0) {
                        [self readExtData:inputStream];
                    }
                    break;

                case 0x0001:
                    group.groupId = [inputStream readInt32];
                    group.groupId = CFSwapInt32LittleToHost(group.groupId);
                    break;

                case 0x0002:
                    group.name = [inputStream readCString:fieldSize encoding:NSUTF8StringEncoding];
                    break;

                case 0x0003:
                    [inputStream read:dateBuffer length:fieldSize];
                    group.creationTime = [Kdb3Date fromPacked:dateBuffer];
                    break;

                case 0x0004:
                    [inputStream read:dateBuffer length:fieldSize];
                    group.lastModificationTime = [Kdb3Date fromPacked:dateBuffer];
                    break;

                case 0x0005:
                    [inputStream read:dateBuffer length:fieldSize];
                    group.lastAccessTime = [Kdb3Date fromPacked:dateBuffer];
                    break;

                case 0x0006:
                    [inputStream read:dateBuffer length:fieldSize];
                    group.expiryTime = [Kdb3Date fromPacked:dateBuffer];
                    break;

                case 0x0007:
                    image = [inputStream readInt32];
                    group.image = CFSwapInt32LittleToHost(image);
                    break;

                case 0x0008: {
                    uint16_t level = [inputStream readInt16];
                    level = CFSwapInt16LittleToHost(level);
                    [levels addObject:[NSNumber numberWithUnsignedInteger:level]];
                    break;
                }

                case 0x0009:
                    group.flags = [inputStream readInt32];
                    group.flags = CFSwapInt32LittleToHost(group.flags);
                    break;

                case 0xFFFF:
                    if (fieldSize != 0) {
                        @throw [NSException exceptionWithName:@"IOException" reason:@"Invalid field size" userInfo:nil];
                    }

                    [groups addObject:group];

                    eos = YES;
                    break;

                default:
                    @throw [NSException exceptionWithName:@"IOException" reason:@"Invalid field type" userInfo:nil];
            }
        }
    }
}

- (void)readEntries:(InputStream*)inputStream {
    uint16_t fieldType;
    uint32_t fieldSize;
    uint8_t buffer[16];
    uint32_t groupId = 0;
    uint32_t image = 0;
    BOOL eos;

    // Parse the entries
    for (uint32_t i = 0; i < numEntries; i++) {
        Kdb3Entry *entry = [[Kdb3Entry alloc] init];

        // Parse the entry
        eos = NO;
        while (!eos) {
            fieldType = [inputStream readInt16];
            fieldType = CFSwapInt16LittleToHost(fieldType);

            fieldSize = [inputStream readInt32];
            fieldSize = CFSwapInt32LittleToHost(fieldSize);

            switch (fieldType) {
                case 0x0000:
                    if (fieldSize > 0) {
                        [self readExtData:inputStream];
                    }
                    break;

                case 0x0001:
                    if (fieldSize != 16) {
                        @throw [NSException exceptionWithName:@"IOException" reason:@"Invalid field size" userInfo:nil];
                    }
                    if ([inputStream read:buffer length:fieldSize] != fieldSize) {
                        @throw [NSException exceptionWithName:@"IOException" reason:@"Failed to read UUID" userInfo:nil];
                    }
                    entry.uuid = [[KdbUUID alloc] initWithBytes:buffer];
                    break;

                case 0x0002:
                    groupId = [inputStream readInt32];
                    groupId = CFSwapInt32LittleToHost(groupId);
                    break;

                case 0x0003:
                    image = [inputStream readInt32];
                    entry.image = CFSwapInt32LittleToHost(image);
                    break;

                case 0x0004:
                    entry.title = [inputStream readCString:fieldSize encoding:NSUTF8StringEncoding];
                    break;

                case 0x0005:
                    entry.url = [inputStream readCString:fieldSize encoding:NSUTF8StringEncoding];
                    break;

                case 0x0006:
                    entry.username = [inputStream readCString:fieldSize encoding:NSUTF8StringEncoding];
                    break;

                case 0x0007:
                    entry.password = [inputStream readCString:fieldSize encoding:NSUTF8StringEncoding];
                    break;

                case 0x0008:
                    entry.notes = [inputStream readCString:fieldSize encoding:NSUTF8StringEncoding];
                    break;

                case 0x0009:
                    if (fieldSize != 5) {
                        @throw [NSException exceptionWithName:@"IOException" reason:@"Invalid field size" userInfo:nil];
                    }
                    [inputStream read:buffer length:fieldSize];
                    entry.creationTime = [Kdb3Date fromPacked:buffer];
                    break;

                case 0x000A:
                    if (fieldSize != 5) {
                        @throw [NSException exceptionWithName:@"IOException" reason:@"Invalid field size" userInfo:nil];
                    }
                    [inputStream read:buffer length:fieldSize];
                    entry.lastModificationTime = [Kdb3Date fromPacked:buffer];
                    break;

                case 0x000B:
                    if (fieldSize != 5) {
                        @throw [NSException exceptionWithName:@"IOException" reason:@"Invalid field size" userInfo:nil];
                    }
                    [inputStream read:buffer length:fieldSize];
                    entry.lastAccessTime = [Kdb3Date fromPacked:buffer];
                    break;

                case 0x000C:
                    if (fieldSize != 5) {
                        @throw [NSException exceptionWithName:@"IOException" reason:@"Invalid field size" userInfo:nil];
                    }
                    [inputStream read:buffer length:fieldSize];
                    entry.expiryTime = [Kdb3Date fromPacked:buffer];
                    break;

                case 0x000D:
                    entry.binaryDesc = [inputStream readCString:fieldSize encoding:NSUTF8StringEncoding];
                    break;

                case 0x000E:
                    if (fieldSize > 0) {
                        entry.binary = [inputStream readData:fieldSize];
                    }
                    break;

                case 0xFFFF:
                    if (fieldSize != 0) {
                        @throw [NSException exceptionWithName:@"IOException" reason:@"Invalid field size" userInfo:nil];
                    }

                    // Find the parent group
                    for (Kdb3Group *g in groups) {
                        if (g.groupId == groupId) {
                            [g addEntry:entry];
                            break;
                        }
                    }

                    [entries addObject:entry];

                    eos = YES;
                    break;

                default:
                    @throw [NSException exceptionWithName:@"IOException" reason:@"Invalid field type" userInfo:nil];
            }
        }
    }
}

- (void)readExtData:(InputStream*)inputStream {
    uint16_t fieldType;
    uint32_t fieldSize;
    uint8_t buffer[32];
	BOOL eos = NO;

	while (!eos) {
        fieldType = [inputStream readInt16];
        fieldType = CFSwapInt16LittleToHost(fieldType);

        fieldSize = [inputStream readInt32];
        fieldSize = CFSwapInt32LittleToHost(fieldSize);

		switch (fieldType) {
            case 0x0000:
                // Ignore field
                [inputStream skip:fieldSize];
                break;

            case 0x0001:
                if (fieldSize != 32) {
                    @throw [NSException exceptionWithName:@"IOException" reason:@"Invalid field size" userInfo:nil];
                }

                [inputStream read:buffer length:fieldSize];

                // Compare the header hash
                if (memcmp(headerHash.bytes, buffer, fieldSize) != 0) {
                    @throw [NSException exceptionWithName:@"IOException" reason:@"Header hash does not match" userInfo:nil];
                }
                break;

            case 0x0002:
                // Ignore random data
                [inputStream skip:fieldSize];
                break;

            case 0xFFFF:
                eos = YES;
                break;

            default:
                @throw [NSException exceptionWithName:@"IOException" reason:@"Invalid field type" userInfo:nil];
                break;
		}
	}
}

- (Kdb3Tree*)buildTree {
    uint16_t level1;
    uint16_t level2;
    int i;
    int j;

    Kdb3Tree *tree = [[Kdb3Tree alloc] init];
    tree.rounds = keyEncRounds;
    tree.flags = headerFlags;

    Kdb3Group *root = [[Kdb3Group alloc] init];
    root.name = @"$ROOT$";
    root.parent = nil;
    root.canAddEntries = NO;
    tree.root = root;

    // Find the parent for every group
    for (i = 0; i < [groups count]; i++) {
        Kdb3Group *group = [groups objectAtIndex:i];
        level1 = [[levels objectAtIndex:i] unsignedIntValue];

        if (level1 == 0) {
            [root addGroup:group];
            continue;
        }

        // The first item with a lower level is the parent
        for (j = i - 1; j >= 0; j--) {
            level2 = [[levels objectAtIndex:j] unsignedIntValue];
            if (level2 < level1) {
                if (level1 - level2 != 1) {
                    @throw [NSException exceptionWithName:@"InvalidData" reason:@"InvalidTree" userInfo:nil];
                } else {
                    break;
                }
            }
            if (j == 0) {
                @throw [NSException exceptionWithName:@"InvalidData" reason:@"InvalidTree" userInfo:nil];
            }
        }
        
        Kdb3Group *parent = [groups objectAtIndex:j];
        [parent addGroup:group];
    }
    
    return tree;
}

@end
