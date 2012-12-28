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

#import <CommonCrypto/CommonCryptor.h>
#import "Kdb4Reader.h"
#import "Kdb4Parser.h"
#import "AesInputStream.h"
#import "HashedInputStream.h"
#import "GZipInputStream.h"
#import "Arc4RandomStream.h"
#import "Salsa20RandomStream.h"
#import "KdbPassword.h"
#import "UUID.h"

#define VERSION_CRITICAL_MAX_32 0x00030000
#define VERSION_CRITICAL_MASK 0xFFFF0000

@interface Kdb4Reader (PrivateMethods)
- (void)readHeader:(InputStream*)inputStream;
@end

@implementation Kdb4Reader

- (void)dealloc {
    [comment release];
    [cipherUuid release];
    [masterSeed release];
    [transformSeed release];
    [encryptionIv release];
    [protectedStreamKey release];
    [streamStartBytes release];
    [super dealloc];
}

- (KdbTree*)load:(InputStream*)inputStream withPassword:(KdbPassword*)kdbPassword {
    // Read the header
    [self readHeader:inputStream];
    
    // Check the cipher algorithm
    if (![cipherUuid isEqual:[UUID getAESUUID]]) {
        @throw [NSException exceptionWithName:@"IOException" reason:@"Unsupported cipher" userInfo:nil];
    }
    
    // Create the AES input stream
    NSData *key = [kdbPassword createFinalKeyForVersion:4 masterSeed:masterSeed transformSeed:transformSeed rounds:rounds];
    AesInputStream *aesInputStream = [[[AesInputStream alloc] initWithInputStream:inputStream key:key iv:encryptionIv] autorelease];
    
    // Verify the stream start bytes match
    NSData *startBytes = [aesInputStream readData:32];
    if (![startBytes isEqual:streamStartBytes]) {
        @throw [NSException exceptionWithName:@"IOException" reason:@"Failed to decrypt" userInfo:nil];
    }
    
    // Create the hashed input stream and swap in the compression input stream if compressed
    InputStream *stream = [[[HashedInputStream alloc] initWithInputStream:aesInputStream] autorelease];
    if (compressionAlgorithm == COMPRESSION_GZIP) {
        stream = [[[GZipInputStream alloc] initWithInputStream:stream] autorelease];
    }
    
    // Create the CRS Algorithm
    RandomStream *randomStream = nil;
    if (randomStreamID == CSR_SALSA20) {
        randomStream = [[[Salsa20RandomStream alloc] init:protectedStreamKey] autorelease];
    } else if (randomStreamID == CSR_ARC4VARIANT) {
        randomStream = [[[Arc4RandomStream alloc] init:protectedStreamKey] autorelease];
    } else {
        @throw [NSException exceptionWithName:@"IOException" reason:@"Unsupported CSR algorithm" userInfo:nil];
    }
    
    // Parse the tree
    Kdb4Parser *parser = [[[Kdb4Parser alloc] initWithRandomStream:randomStream] autorelease];
    Kdb4Tree *tree = [parser parse:stream];
    
    // Copy some parameters into the KdbTree
    tree.rounds = rounds;
    tree.compressionAlgorithm = compressionAlgorithm;
    
    return tree;
}

- (void)readHeader:inputStream {
    uint8_t buffer[16];

    uint32_t sig1 = [inputStream readInt32];
    sig1 = CFSwapInt32LittleToHost(sig1);

    uint32_t sig2 = [inputStream readInt32];
    sig2 = CFSwapInt32LittleToHost(sig2);
    if (!(sig1 == KDB4_SIG1 && sig2 == KDB4_SIG2)) {
        @throw [NSException exceptionWithName:@"IOException" reason:@"Invalid signature" userInfo:nil];
    }

    uint32_t version = [inputStream readInt32];
    version = CFSwapInt32LittleToHost(version);

    if ((version & VERSION_CRITICAL_MASK) > (VERSION_CRITICAL_MAX_32 & VERSION_CRITICAL_MASK)) {
        @throw [NSException exceptionWithName:@"IOException" reason:@"Unsupported version" userInfo:nil];
    }

    BOOL eoh = NO;
    while (!eoh) {
        uint8_t fieldType = [inputStream readInt8];

        uint16_t fieldSize = [inputStream readInt16];
        fieldSize = CFSwapInt16LittleToHost(fieldSize);
        
        switch (fieldType) {
            case HEADER_EOH:
                [inputStream read:buffer length:fieldSize];
                eoh = YES;
                break;
            
            case HEADER_COMMENT:
                // FIXME this should prolly be a string
                comment = [[inputStream readData:fieldSize] retain];
                break;
            
            case HEADER_CIPHERID:
                if (fieldSize != 16) {
                    @throw [NSException exceptionWithName:@"IOException" reason:@"Invalid cipher id" userInfo:nil];
                }
                [inputStream read:buffer length:fieldSize];
                cipherUuid = [[UUID alloc] initWithBytes:buffer];
                break;
            
            case HEADER_MASTERSEED:
                if (fieldSize != 32) {
                    @throw [NSException exceptionWithName:@"IOException" reason:@"Invalid field size" userInfo:nil];
                }
                masterSeed = [[inputStream readData:fieldSize] retain];
                break;
            
            case HEADER_TRANSFORMSEED:
                if (fieldSize != 32) {
                    @throw [NSException exceptionWithName:@"IOException" reason:@"Invalid field size" userInfo:nil];
                }
                
                transformSeed = [[inputStream readData:fieldSize] retain];
                break;
            
            case HEADER_ENCRYPTIONIV:
                encryptionIv = [[inputStream readData:fieldSize] retain];
                break;
            
            case HEADER_PROTECTEDKEY:
                protectedStreamKey = [[inputStream readData:fieldSize] retain];
                break;
            
            case HEADER_STARTBYTES:
                streamStartBytes = [[inputStream readData:fieldSize] retain];
                break;
            
            case HEADER_TRANSFORMROUNDS:
                rounds = [inputStream readInt64];
                rounds = CFSwapInt64LittleToHost(rounds);
                break;
            
            case HEADER_COMPRESSION:
                compressionAlgorithm = [inputStream readInt32];
                compressionAlgorithm = CFSwapInt32LittleToHost(compressionAlgorithm);
                if (compressionAlgorithm >= COMPRESSION_COUNT) {
                    @throw [NSException exceptionWithName:@"IOException" reason:@"Invalid compression" userInfo:nil];
                }
                break;
            
            case HEADER_RANDOMSTREAMID:
                randomStreamID = [inputStream readInt32];
                randomStreamID = CFSwapInt32LittleToHost(randomStreamID);
                if (randomStreamID >= CSR_COUNT) {
                    @throw [NSException exceptionWithName:@"IOException" reason:@"Invalid CSR algorithm" userInfo:nil];
                }
                break;
            
            default:
                @throw [NSException exceptionWithName:@"InvalidHeader" reason:@"InvalidField" userInfo:nil];
        }
    }
}

@end
