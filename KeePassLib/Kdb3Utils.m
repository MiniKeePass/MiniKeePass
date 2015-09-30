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

#import "Kdb3Utils.h"
#import <CommonCrypto/CommonDigest.h>

@implementation Kdb3Utils

+ (NSData *)hashHeader:(kdb3_header_t *)header {
    uint8_t *buffer = (uint8_t *)header;
    CC_LONG endCount = sizeof(header->masterSeed2) + sizeof(header->keyEncRounds);
    CC_LONG startCount = sizeof(kdb3_header_t) - sizeof(header->contentsHash) - endCount;
    uint8_t hash[32];

    CC_SHA256_CTX ctx;
    CC_SHA256_Init(&ctx);
    CC_SHA256_Update(&ctx, buffer, startCount);
    CC_SHA256_Update(&ctx, buffer + (sizeof(kdb3_header_t) - endCount), endCount);
    CC_SHA256_Final(hash, &ctx);

    return [NSData dataWithBytes:hash length:sizeof(hash)];
}

@end
