/*
 * Copyright 2017 Jason Rush and John Flanagan. All rights reserved.
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

#import "CipherStreamFactory.h"
#import "AesInputStream.h"
#import "AesOutputStream.h"
#import "ChaCha20InputStream.h"
#import "ChaCha20OutputStream.h"
#import "Utils.h"

@implementation CipherStreamFactory

+ (InputStream *)getInputStream:(KdbUUID *)uuid stream:(InputStream*)s key:(NSData *)key iv:(NSData *)iv {
    InputStream *stream = nil;
    
    if ([uuid isEqual:[KdbUUID getAESUUID]]) {
        stream = [[AesInputStream alloc] initWithInputStream:s key:key iv:iv];
    } else if ([uuid isEqual:[KdbUUID getChaCha20UUID]]) {
        stream = [[ChaCha20InputStream alloc] initWithInputStream:s key:key iv:iv];
    } else {
        @throw [NSException exceptionWithName:@"CryptoException" reason:@"Unknown cipher" userInfo:nil];
    }
    
    return stream;
}

+ (OutputStream *)getOutputStream:(KdbUUID *)uuid stream:(OutputStream*)s key:(NSData *)key iv:(NSData *)iv {
    OutputStream *stream = nil;
    
    if ([uuid isEqual:[KdbUUID getAESUUID]]) {
        stream = [[AesOutputStream alloc] initWithOutputStream:s key:key iv:iv];
    } else if ([uuid isEqual:[KdbUUID getChaCha20UUID]]) {
        stream = [[ChaCha20OutputStream alloc] initWithOutputStream:s key:key iv:iv];
    } else {
        @throw [NSException exceptionWithName:@"CryptoException" reason:@"Unknown cipher" userInfo:nil];
    }
    
    return stream;
}

@end
