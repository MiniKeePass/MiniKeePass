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

#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonCryptor.h>
#import "InputStream.h"
#import "BlockCipher.h"

#define BLOCK_BUFFERSIZE (512*1024)

@interface ChaCha20InputStream : InputStream {

    InputStream *inputStream;
    
    BlockCipher *cipher;
    
    uint8_t buffer[BLOCK_BUFFERSIZE];
    uint32_t bufferOffset;
    uint32_t bufferSize;
    BOOL eof;
}

- (id)initWithInputStream:(InputStream *)stream key:(NSData *)key iv:(NSData *)iv;

@end
