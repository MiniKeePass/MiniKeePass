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

            AES_UUID = [[NSData alloc] initWithBytes:bytes length:16];
        }
    }
    return AES_UUID;
}

@end
