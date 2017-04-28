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

#import "UUID.h"

static KdbUUID *AES_UUID;
static KdbUUID *AES_KDF_UUID;
static KdbUUID *CHACHA20_UUID;
static KdbUUID *ARGON2_UUID;

@implementation KdbUUID

@synthesize uuid;

- (id)init {
    self = [super init];
	if (self) {
		uuid = CFUUIDCreate(kCFAllocatorDefault);
	}
	return self;
}

- (id)initWithBytes:(uint8_t *)bytes {
    self = [super init];
	if (self) {
		uuid = CFUUIDCreateWithBytes(kCFAllocatorDefault, bytes[0], bytes[1], bytes[2], bytes[3], bytes[4], bytes[5], bytes[6], bytes[7], bytes[8], bytes[9], bytes[10], bytes[11], bytes[12], bytes[13], bytes[14], bytes[15]);
	}
	return self;
}

- (id)initWithData:(NSData *)data {
    self = [super init];
	if (self) {
        uint8_t bytes[16];
        [data getBytes:bytes length:sizeof(bytes)];

		uuid = CFUUIDCreateWithBytes(kCFAllocatorDefault, bytes[0], bytes[1], bytes[2], bytes[3], bytes[4], bytes[5], bytes[6], bytes[7], bytes[8], bytes[9], bytes[10], bytes[11], bytes[12], bytes[13], bytes[14], bytes[15]);
	}
	return self;
}

- (id)initWithString:(NSString *)string {
    self = [super init];
	if (self) {
        uuid = CFUUIDCreateFromString(kCFAllocatorDefault, (CFStringRef)string);
	}
	return self;
}

- (void)dealloc {
    CFRelease(uuid);
}

- (void)getBytes:(uint8_t*)bytes length:(NSUInteger)length {
    if (length < 16) {
        @throw [NSException exceptionWithName:@"IllegalArgumentException" reason:@"Length is less then 16 bytes" userInfo:nil];
    }
    
    CFUUIDBytes uuidBytes = CFUUIDGetUUIDBytes(uuid);
    memcpy(bytes, &uuidBytes, 16);
}

- (NSData *)getData {
    uint8_t bytes[16];

    CFUUIDBytes uuidBytes = CFUUIDGetUUIDBytes(uuid);
    memcpy(bytes, &uuidBytes, 16);

    return [NSData dataWithBytes:bytes length:sizeof(bytes)];
}

- (BOOL)isEqual:(id)object {
    if (self == object) {
        return YES;
    }
    
    if ([object isKindOfClass:[KdbUUID class]]) {
        CFUUIDBytes uuidBytes1 = CFUUIDGetUUIDBytes(uuid);
        CFUUIDBytes uuidBytes2 = CFUUIDGetUUIDBytes(((KdbUUID*)object).uuid);
        return memcmp(&uuidBytes1, &uuidBytes2, sizeof(CFUUIDBytes)) == 0;
    }
    
    return NO;
}

- (NSString*)description {
    NSString *uuidString = (NSString *)CFBridgingRelease(CFUUIDCreateString(NULL, uuid)); // FIXME Double check CFBridgingRelease
    return uuidString;
}

+ (KdbUUID *)uuid {
    return [[KdbUUID alloc] init];
}

+ (KdbUUID *)nullUuid {
    uint8_t bytes[16] = {0};
    return [[KdbUUID alloc] initWithBytes:bytes];
}

+ (KdbUUID*)getAESUUID {
    @synchronized(self) {
        if (!AES_UUID) {
            uint8_t bytes[16];
            bytes[0]=0x31; bytes[1]=0xC1;
            bytes[2]=0xF2; bytes[3]=0xE6;
            bytes[4]=0xBF; bytes[5]=0x71;
            bytes[6]=0x43; bytes[7]=0x50;
            bytes[8]=0xBE; bytes[9]=0x58;
            bytes[10]=0x05; bytes[11]=0x21;
            bytes[12]=0x6A; bytes[13]=0xFC;
            bytes[14]=0x5A; bytes[15]=0xFF;

            AES_UUID = [[KdbUUID alloc] initWithBytes:bytes];
        }
    }
    return AES_UUID;
}
+ (KdbUUID*)getAES_KDFUUID {
    @synchronized(self) {
        if (!AES_KDF_UUID) {
            uint8_t bytes[16];
            bytes[0]=0xC9; bytes[1]=0xD9;
            bytes[2]=0xF3; bytes[3]=0x9A;
            bytes[4]=0x62; bytes[5]=0x8A;
            bytes[6]=0x44; bytes[7]=0x60;
            bytes[8]=0xBF; bytes[9]=0x74;
            bytes[10]=0x0D; bytes[11]=0x08;
            bytes[12]=0xC1; bytes[13]=0x8A;
            bytes[14]=0x4F; bytes[15]=0xEA;

            AES_KDF_UUID = [[KdbUUID alloc] initWithBytes:bytes];
        }
    }
    return AES_KDF_UUID;
}

+ (KdbUUID*)getChaCha20UUID {
    @synchronized(self) {
        if (!CHACHA20_UUID) {
            uint8_t bytes[16];
            bytes[0]=0xD6; bytes[1]=0x03;
            bytes[2]=0x8A; bytes[3]=0x2B;
            bytes[4]=0x8B; bytes[5]=0x6F;
            bytes[6]=0x4C; bytes[7]=0xB5;
            bytes[8]=0xA5; bytes[9]=0x24;
            bytes[10]=0x33; bytes[11]=0x9A;
            bytes[12]=0x31; bytes[13]=0xDB;
            bytes[14]=0xB5; bytes[15]=0x9A;
            
            CHACHA20_UUID = [[KdbUUID alloc] initWithBytes:bytes];
        }
    }
    return CHACHA20_UUID;
}

+ (KdbUUID*)getArgon2UUID {
    @synchronized(self) {
        if (!ARGON2_UUID) {
            uint8_t bytes[16];
            bytes[0]=0xEF; bytes[1]=0x63;
            bytes[2]=0x6D; bytes[3]=0xDF;
            bytes[4]=0x8C; bytes[5]=0x29;
            bytes[6]=0x44; bytes[7]=0x4B;
            bytes[8]=0x91; bytes[9]=0xF7;
            bytes[10]=0xA9; bytes[11]=0xA4;
            bytes[12]=0x03; bytes[13]=0xE3;
            bytes[14]=0x0A; bytes[15]=0x0C;
            
            ARGON2_UUID = [[KdbUUID alloc] initWithBytes:bytes];
        }
    }
    return ARGON2_UUID;
}

@end
