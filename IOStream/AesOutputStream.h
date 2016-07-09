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

#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonCryptor.h>
#import "OutputStream.h"

@interface AesOutputStream : OutputStream {
    OutputStream *outputStream;
    
    CCCryptorRef cryptorRef;
    
    size_t bufferCapacity;
    uint8_t *buffer;
}

- (id)initWithOutputStream:(OutputStream *)stream key:(NSData *)key iv:(NSData *)iv;

@end
