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

#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonCryptor.h>
#import <CommonCrypto/CommonHMAC.h>
#import "Kdb4Reader.h"
#import "Kdb4Parser.h"
#import "FileInputStream.h"
#import "HashedInputStream.h"
#import "HmacInputStream.h"
#import "GZipInputStream.h"
#import "Arc4RandomStream.h"
#import "Salsa20RandomStream.h"
#import "ChaCha20RandomStream.h"
#import "KdbPassword.h"
#import "CipherStreamFactory.h"

#define VERSION_CRITICAL_MAX_32_4 0x00040000  // KDBX 4
#define VERSION_CRITICAL_MAX_32 0x00030000
#define VERSION_CRITICAL_MASK 0xFFFF0000

@interface Kdb4Reader (PrivateMethods)
- (void)readHeader:(InputStream*)inputStream;
- (void)readInnerHeader:(InputStream*)inputStream;
@end

@implementation Kdb4Reader

- (KdbTree*)load:(FileInputStream*)inputStream withPassword:(KdbPassword*)kdbPassword {
    // Read the header
    [self readHeader:inputStream];

    uint8_t hmackey64[64];
    uint8_t *mseed = (uint8_t *) masterSeed.bytes;
    NSData *key = [kdbPassword createFinalKeyKDBX4:kdfParams masterSeed:mseed HmacKey64:hmackey64 ];

    InputStream *stream;
    InputStream *xmlStream;
    if (dbVersion < VERSION_CRITICAL_MAX_32_4) {  // KDBX 3.1
        
        // Create the encrypted input stream (ALWAYS AES for 3.1 files)
        stream = [CipherStreamFactory getInputStream:cipherUuid stream:inputStream key:key iv:encryptionIv];

        // Verify the stream start bytes match for 3.1
        NSData *startBytes = [stream readData:32];

        if (![startBytes isEqual:streamStartBytes]) {
            @throw [NSException exceptionWithName:@"IOException" reason:@"Failed to decrypt" userInfo:nil];
        }
        
        // Create the hashed input stream and
        stream = [[HashedInputStream alloc] initWithInputStream:stream];

    } else {  // KDBX 4
        // Reread the header bytes into an array to find the Hash
        off_t headerLen = [inputStream getpos];
        [inputStream seek:0];
        NSData *headerBytes = [inputStream readData:(NSUInteger)headerLen];
        
        // Check the header Hash
        uint8_t headerReadHash[CC_SHA256_DIGEST_LENGTH];
        CC_SHA256(headerBytes.bytes, (CC_LONG)headerBytes.length, headerReadHash);

        NSData *headerStoredHash = [inputStream readData:32];
        if (memcmp(headerReadHash, headerStoredHash.bytes, 32) != 0) {
            @throw [NSException exceptionWithName:@"IOFileCorrupt" reason:@"Header data corrupt" userInfo:nil];
        }
        
        // Check the header HMAC-SHA-256
        uint8_t headerReadHmac[CC_SHA256_DIGEST_LENGTH];
        uint8_t headerStoredHmac[CC_SHA256_DIGEST_LENGTH];
        NSData *hmacKey = [HmacInputStream getHMACKey:(void *)hmackey64 keylen:64 blockIndex:ULLONG_MAX];
        CCHmac(kCCHmacAlgSHA256, hmacKey.bytes, hmacKey.length, headerBytes.bytes, (size_t)headerBytes.length, headerReadHmac);
        [inputStream read:headerStoredHmac length:32];
        if (memcmp(headerReadHmac, headerStoredHmac, 32) != 0) {
            @throw [NSException exceptionWithName:@"IOFileCorrupt" reason:@"Header data corrupt" userInfo:nil];
        }
        
        // Create the HMAC Block input stream
        NSData *hmacKeyData = [[NSData alloc] initWithBytes:hmackey64 length:64];
        HmacInputStream *hmacStream = [[HmacInputStream alloc] initWithInputStream:inputStream key:hmacKeyData];
        
        // Create the encrypted input stream
        stream = [CipherStreamFactory getInputStream:cipherUuid stream:hmacStream key:key iv:encryptionIv];
    }
    
    // Decompress input stream if compressed
    if (compressionAlgorithm == COMPRESSION_GZIP) {
        xmlStream = [[GZipInputStream alloc] initWithInputStream:stream];
    } else {
        xmlStream = stream;
    }
    
    if (dbVersion >= VERSION_CRITICAL_MAX_32_4) {  // KDBX 4
        [self readInnerHeader:xmlStream];
    }

    if (protectedStreamKey == nil) {
        @throw [NSException exceptionWithName:@"IOException" reason:@"Inner Protected Stream Key NOT FOUND." userInfo:nil];
    }
    
    // Create the CRS Algorithm
    RandomStream *randomStream = nil;
    if (randomStreamID == CSR_SALSA20) {
        randomStream = [[Salsa20RandomStream alloc] init:protectedStreamKey];
    } else if (randomStreamID == CSR_ARC4VARIANT) {
        randomStream = [[Arc4RandomStream alloc] init:protectedStreamKey];
    } else if (randomStreamID == CSR_CHACHA20) {
        randomStream = [[ChaCha20RandomStream alloc] init:protectedStreamKey];
    } else {
        @throw [NSException exceptionWithName:@"IOException" reason:@"Unsupported CSR algorithm" userInfo:nil];
    }

    // Parse the tree
    Kdb4Parser *parser = [[Kdb4Parser alloc] initWithRandomStream:randomStream];
    Kdb4Tree *tree = [parser parse:xmlStream dbVersion:dbVersion];

    // Copy parameters from the header into the KdbTree
    tree.kdfParams = kdfParams;
    tree.customPluginData = customPluginData;
    tree.headerBinaries = binaryData;
    tree.compressionAlgorithm = compressionAlgorithm;
    tree.encryptionAlgorithm = cipherUuid;
    
    return tree;
}

- (void)readHeader:(InputStream*)inputStream {
    uint8_t buffer[16];
    
    uint32_t sig1 = [inputStream readInt32];
    sig1 = CFSwapInt32LittleToHost(sig1);

    uint32_t sig2 = [inputStream readInt32];
    sig2 = CFSwapInt32LittleToHost(sig2);
    if (!(sig1 == KDB4_SIG1 && sig2 == KDB4_SIG2)) {
        @throw [NSException exceptionWithName:@"IOException" reason:@"Invalid signature" userInfo:nil];
    }

    dbVersion = [inputStream readInt32];
    dbVersion = CFSwapInt32LittleToHost(dbVersion);

    if ((dbVersion & VERSION_CRITICAL_MASK) > (VERSION_CRITICAL_MAX_32_4 & VERSION_CRITICAL_MASK)) {
        @throw [NSException exceptionWithName:@"IOException" reason:@"Unsupported version" userInfo:nil];
    }
    
    uint64_t pvali64;
    kdfParams = [[VariantDictionary alloc] init];

    BOOL eoh = NO;
    while (!eoh) {
        uint8_t fieldType = [inputStream readInt8];
        int32_t fieldSize;

        if (dbVersion >= VERSION_CRITICAL_MAX_32_4) {
            fieldSize = [inputStream readInt32];
            fieldSize = CFSwapInt32LittleToHost(fieldSize);
        } else {
            uint16_t oldfieldSize = [inputStream readInt16];
            oldfieldSize = CFSwapInt16LittleToHost(oldfieldSize);
            fieldSize = oldfieldSize;
        }
        
        switch (fieldType) {
            case HEADER_EOH:
                [inputStream read:buffer length:fieldSize];
                eoh = YES;
                break;
            
            case HEADER_COMMENT:
                // FIXME this should prolly be a string
                comment = [inputStream readData:fieldSize];
                break;
            
            case HEADER_CIPHERID:
                if (fieldSize != 16) {
                    @throw [NSException exceptionWithName:@"IOException" reason:@"Invalid cipher id" userInfo:nil];
                }
                [inputStream read:buffer length:fieldSize];
                cipherUuid = [[KdbUUID alloc] initWithBytes:buffer];
                break;
            
            case HEADER_MASTERSEED:
                if (fieldSize != 32) {
                    @throw [NSException exceptionWithName:@"IOException" reason:@"Invalid field size" userInfo:nil];
                }
                masterSeed = [inputStream readData:fieldSize];
                break;
            
            case HEADER_TRANSFORMSEED:      // Obsolete in KDBX 4
                if (fieldSize != 32) {
                    @throw [NSException exceptionWithName:@"IOException" reason:@"Invalid field size" userInfo:nil];
                }
                    // Set the KDFparameters UUID if not set.
                if (kdfParams[KDF_KEY_UUID_BYTES] == nil) {
                    [kdfParams addByteArray:[[KdbUUID getAES_KDFUUID] getData] forKey:KDF_KEY_UUID_BYTES];
                }
                [kdfParams addByteArray:[inputStream readData:fieldSize] forKey:KDF_AES_KEY_SEED];
                break;
            
            case HEADER_ENCRYPTIONIV:
                encryptionIv = [inputStream readData:fieldSize];
                break;
            
            case HEADER_PROTECTEDKEY:     // Obsolete in KDBX 4
                protectedStreamKey = [inputStream readData:fieldSize];
                break;
            
            case HEADER_STARTBYTES:  // Obsolete in KDBX 4
                streamStartBytes = [inputStream readData:fieldSize];
                break;
            
            case HEADER_TRANSFORMROUNDS:    // Obsolete in KDBX 4
                if (kdfParams[KDF_KEY_UUID_BYTES] == nil) {
                    [kdfParams addByteArray:[[KdbUUID getAES_KDFUUID] getData] forKey:KDF_KEY_UUID_BYTES];
                }
                pvali64 = [inputStream readInt64];
                pvali64 = CFSwapInt64LittleToHost(pvali64);
                [kdfParams addUInt64:pvali64 forKey:KDF_AES_KEY_ROUNDS];
                break;
            
            case HEADER_COMPRESSION:
                compressionAlgorithm = [inputStream readInt32];
                compressionAlgorithm = CFSwapInt32LittleToHost(compressionAlgorithm);
                if (compressionAlgorithm >= COMPRESSION_COUNT) {
                    @throw [NSException exceptionWithName:@"IOException" reason:@"Invalid compression" userInfo:nil];
                }
                break;
            
            case HEADER_RANDOMSTREAMID:    // Obsolete in KDBX 4
                randomStreamID = [inputStream readInt32];
                randomStreamID = CFSwapInt32LittleToHost(randomStreamID);
                if (randomStreamID >= CSR_COUNT) {
                    @throw [NSException exceptionWithName:@"IOException" reason:@"Invalid CSR algorithm" userInfo:nil];
                }
                break;
            
            case HEADER_KDFPARMETERS:
                [kdfParams deserialize:inputStream];
                break;
            case HEADER_PUBLICCUSTOM:
                [customPluginData deserialize:inputStream];
                break;
                
            default:
                @throw [NSException exceptionWithName:@"InvalidHeader" reason:@"InvalidField" userInfo:nil];
        }
    }
}

- (void)readInnerHeader:(InputStream*)inputStream {
    BOOL eoh = NO;
    while (!eoh) {
        uint8_t fieldType = [inputStream readInt8];
        int32_t fieldSize;
        NSData *bdata;
        
        fieldSize = [inputStream readInt32];
        fieldSize = CFSwapInt32LittleToHost(fieldSize);
        
        switch (fieldType) {
            case INNER_HEADER_EOH:
                bdata = [inputStream readData:fieldSize];
                eoh = YES;
                break;
            case INNER_HEADER_RANDOMSTREAMID:
                randomStreamID = [inputStream readInt32];
                randomStreamID = CFSwapInt32LittleToHost(randomStreamID);
                if (randomStreamID >= CSR_COUNT) {
                    @throw [NSException exceptionWithName:@"IOException" reason:@"Invalid CSR algorithm" userInfo:nil];
                }
                break;
            case INNER_HEADER_RANDOMSTREAMKEY:
                protectedStreamKey = [inputStream readData:fieldSize];
                break;
            case INNER_HEADER_BINARY:
                if (binaryData == nil) {
                    binaryData = [[NSMutableArray alloc] init];
                }
                bdata = [inputStream readData:fieldSize];
                [binaryData addObject:bdata];
                break;
            default:
                @throw [NSException exceptionWithName:@"InvalidParameterField" reason:@"Inner Header BadFieldType" userInfo:nil];
        }
    }
}

@end
