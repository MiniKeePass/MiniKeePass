//
//  UUID.m
//  KeePass2
//
//  Created by Qiang Yu on 1/2/10.
//  Copyright 2010 Qiang Yu. All rights reserved.
//

#import "UUID.h"

static UUID *AES_UUID;

@implementation UUID

- (id)init {
    self = [super init];
	if (self) {
		uuid = CFUUIDCreate(kCFAllocatorDefault);
	}
	return self;
}

- (id)initWithBytes:(uint8_t*)bytes {
    self = [super init];
	if (self) {
		uuid = CFUUIDCreateWithBytes(kCFAllocatorDefault, bytes[0], bytes[1], bytes[2], bytes[3], bytes[4], bytes[5], bytes[6], bytes[7], bytes[8], bytes[9], bytes[10], bytes[11], bytes[12], bytes[13], bytes[14], bytes[15]);
	}
	return self;
}

- (void)dealloc {
    CFRelease(uuid);
    [super dealloc];
}

- (void)getBytes:(uint8_t*)bytes length:(NSUInteger)length {
    if (length < 16) {
        @throw [NSException exceptionWithName:@"IllegalArgumentException" reason:@"Length is less then 16 bytes" userInfo:nil];
    }
    
    CFUUIDBytes uuidBytes = CFUUIDGetUUIDBytes(uuid);
    memcpy(bytes, &uuidBytes, 16);
}

+ (UUID*)getAESUUID {
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

            AES_UUID = [[UUID alloc] initWithBytes:bytes];
        }
    }
    return AES_UUID;
}

@end
