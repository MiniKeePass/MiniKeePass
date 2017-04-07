//
//  Password.m
//  KeePass2
//
//  Created by Qiang Yu on 1/5/10.
//  Copyright 2010 Qiang Yu. All rights reserved.
//

#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonCryptor.h>
#import "argon2.h"

#import "Kdb4Node.h"
#import "KdbPassword.h"
#import "DDXML.h"
#import "DDXMLElementAdditions.h"
#import "Base64.h"

const uint64_t DEFAULT_AES_TRANSFORMATION_ROUNDS = 6000;

const uint64_t DEFAULT_ARGON2_ITERATIONS =         2;
const uint64_t DEFAULT_ARGON2_MEMORY =             1024*1024;
const uint64_t DEFAULT_ARGON2_PARALLELISM =        2;
const uint64_t DEFAULT_ARGON2_VERSION =            0x13;


@interface KdbPassword () {
    NSString *password;
    NSStringEncoding passswordEncoding;
    NSString *keyFile;
}

- (void)createMasterKeyV3:(uint8_t *)masterKey;
- (void)createMasterKeyV4:(uint8_t *)masterKey;

- (NSData*)loadKeyFileV3:(NSString*)filename;
- (NSData*)loadKeyFileV4:(NSString*)filename;

- (NSData*)loadXmlKeyFile:(NSString*)filename;
- (NSData*)loadBinKeyFile32:(NSFileHandle*)fh;
- (NSData*)loadHexKeyFile64:(NSFileHandle*)fh;
- (NSData*)loadHashKeyFile:(NSFileHandle*)fh;

+ (void)checkArgon2Parameters:(VariantDictionary *)kdfParams;
@end

int hex2dec(char c);

@implementation KdbPassword

- (id)initWithPassword:(NSString*)inPassword
      passwordEncoding:(NSStringEncoding)inPasswordEncoding
               keyFile:(NSString*)inKeyFile {
    self = [super init];
    if (self) {
        password = [inPassword copy];
        passswordEncoding = inPasswordEncoding;
        keyFile = [inKeyFile copy];
    }
    return self;
}

- (NSData*)createFinalKeyForVersion:(uint8_t)version
                         masterSeed:(NSData*)masterSeed
                      transformSeed:(NSData*)transformSeed
                             rounds:(uint64_t)rounds {
    // Generate the master key from the credentials
    uint8_t masterKey[32];
    if (version == 3) {
        [self createMasterKeyV3:masterKey];
    } else {
        [self createMasterKeyV4:masterKey];
    }

    // Transform the key
    CCCryptorRef cryptorRef;
    if( CCCryptorCreate(kCCEncrypt, kCCAlgorithmAES128, kCCOptionECBMode, transformSeed.bytes, kCCKeySizeAES256, nil, &cryptorRef) != kCCSuccess ) {
        @throw [NSException exceptionWithName:@"CryptoException" reason:@"Failed create ref" userInfo:nil];
    };

    size_t tmp;
    for (int i = 0; i < rounds; i++) {
        CCCryptorUpdate(cryptorRef, masterKey, 32, masterKey, 32, &tmp);
    }

    CCCryptorRelease(cryptorRef);

    uint8_t transformedKey[32];
    CC_SHA256(masterKey, 32, transformedKey);

    // Hash the master seed with the transformed key into the final key
    uint8_t finalKey[32];
    CC_SHA256_CTX ctx;
    CC_SHA256_Init(&ctx);
    CC_SHA256_Update(&ctx, masterSeed.bytes, (CC_LONG)masterSeed.length);
    CC_SHA256_Update(&ctx, transformedKey, 32);
    CC_SHA256_Final(finalKey, &ctx);

    return [NSData dataWithBytes:finalKey length:32];
}

- (NSData*)createFinalKeyKDBX4:(VariantDictionary *)kdfparams
                    masterSeed:(uint8_t*)masterSeed
                     HmacKey64:(uint8_t*)hmackey64 {
    
    // Generate the master key from the credentials
    uint8_t masterKey[32];
    [self createMasterKeyV4:masterKey];
    
    [KdbPassword checkKDFParameters:kdfparams];

    UUID *uuid = [[UUID alloc] initWithData:kdfparams[KDF_KEY_UUID_BYTES]];
    
    // Transform the key
    if( [uuid isEqual:[UUID getAES_KDFUUID]] ) {
        CCCryptorRef cryptorRef;
        NSData *transformSeed = kdfparams[KDF_AES_KEY_SEED];
        if( CCCryptorCreate(kCCEncrypt, kCCAlgorithmAES128, kCCOptionECBMode, transformSeed.bytes, kCCKeySizeAES256, nil, &cryptorRef) != kCCSuccess ) {
            @throw [NSException exceptionWithName:@"CryptoException" reason:@"Failed create ref" userInfo:nil];
        };
        
        size_t tmp;
        NSNumber *rounds = kdfparams[KDF_AES_KEY_ROUNDS];
        for (int i = 0; i < [rounds longLongValue]; i++) {
            CCCryptorUpdate(cryptorRef, masterKey, 32, masterKey, 32, &tmp);
        }
        
        CCCryptorRelease(cryptorRef);
        uint8_t transformedKey[32];
        CC_SHA256(masterKey, 32, transformedKey);
        memcpy( masterKey, transformedKey, 32);
    } else if( [uuid isEqual:[UUID getArgon2UUID]] ) {
        uint32_t t_cost = [kdfparams[KDF_ARGON2_KEY_ITERATIONS] unsignedIntValue];
        uint64_t m_cost = [kdfparams[KDF_ARGON2_KEY_MEMORY] unsignedLongLongValue];
        uint32_t parallelism = [kdfparams[KDF_ARGON2_KEY_PARALLELISM] unsignedIntValue];
        uint8_t *salt = (uint8_t *) [kdfparams[KDF_ARGON2_KEY_SALT] bytes];
        uint32_t saltlen = (uint32_t) [kdfparams[KDF_ARGON2_KEY_SALT] length];
        uint8_t result[32];
        argon2d_hash_raw(t_cost, (uint32_t)m_cost/1024, parallelism, masterKey, 32, salt, saltlen, result, 32);
        memcpy( masterKey, result, 32);
    } else {
        @throw [NSException exceptionWithName:@"CryptoException" reason:@"Unknown Algorithm" userInfo:nil];
    }

/*
    uint8_t transformedKey[32];
    CC_SHA256(masterKey, 32, transformedKey);
*/
    
    // Hash the master seed with the transformed key into the final key
    uint8_t finalKey[32];
    uint8_t key64[65];
    
    memcpy( key64, masterSeed, 32 );
    memcpy( &key64[32], masterKey, 32 );
    key64[64] = 1;
/*
    CC_SHA256_CTX ctx;
    CC_SHA256_Init(&ctx);
    CC_SHA256_Update(&ctx, masterSeed, 32);
    CC_SHA256_Update(&ctx, masterKey, 32);
    CC_SHA256_Final(finalKey, &ctx);
*/
    CC_SHA256( key64, 64, finalKey );

    // Find the HmacKey64
 
    // Hash the extended cipher key
    CC_SHA512(key64, 65, hmackey64);
    
    return [NSData dataWithBytes:finalKey length:32];
}

+ (void)checkKDFParameters:(VariantDictionary *)kdf {
    
    UUID *uuid = [[UUID alloc] initWithData:kdf[KDF_KEY_UUID_BYTES]];
    
    if( [uuid isEqual:[UUID getAES_KDFUUID]] ) {
        [self checkAESParameters:kdf];
    } else if( [uuid isEqual:[UUID getArgon2UUID]] ) {
        [self checkArgon2Parameters:kdf];
    } else {
        @throw [NSException exceptionWithName:@"CryptoException" reason:@"Unknown Algorithm" userInfo:nil];
    }
}

+ (void)checkAESParameters:(VariantDictionary *)kdf {
    if( kdf[KDF_AES_KEY_ROUNDS] == nil ) {
        @throw [NSException exceptionWithName:@"CryptoException" reason:@"AES rounds not set" userInfo:nil];
    } else {
        if( [(NSNumber*)kdf[KDF_AES_KEY_ROUNDS] unsignedLongLongValue] <= 0 ) {
            @throw [NSException exceptionWithName:@"CryptoException" reason:@"AES rounds invalid" userInfo:nil];
        }
    }
    
    if( kdf[KDF_AES_KEY_SEED] == nil ) {
        @throw [NSException exceptionWithName:@"CryptoException" reason:@"AES seed not set" userInfo:nil];
    } else {
        if( [kdf[KDF_AES_KEY_SEED] length] != 32 ) {
            @throw [NSException exceptionWithName:@"CryptoException" reason:@"AES seed length error" userInfo:nil];
        }
    }
}

+ (void)checkArgon2Parameters:(VariantDictionary *)kdf {
    // Check the parameters to the Argon2 Key Derivation Function
    if( kdf[KDF_ARGON2_KEY_ITERATIONS] == nil ) {
        @throw [NSException exceptionWithName:@"CryptoException" reason:@"Argon2 iterations not set" userInfo:nil];
    }

    if( kdf[KDF_ARGON2_KEY_MEMORY] == nil ) {
        @throw [NSException exceptionWithName:@"CryptoException" reason:@"Argon2 memory not set" userInfo:nil];
    }

    if( kdf[KDF_ARGON2_KEY_PARALLELISM] == nil ) {
        @throw [NSException exceptionWithName:@"CryptoException" reason:@"Argon2 parallelism not set" userInfo:nil];
    } else {
        if( [(NSNumber *)kdf[KDF_ARGON2_KEY_PARALLELISM] unsignedLongLongValue] <= 0 ) {
            @throw [NSException exceptionWithName:@"CryptoException" reason:@"Argon2 parallelism bad value" userInfo:nil];
        }
    }
    
    if( kdf[KDF_ARGON2_KEY_SALT] == nil ) {
        @throw [NSException exceptionWithName:@"CryptoException" reason:@"Argon2 salt not set" userInfo:nil];
    } else {
        if( [kdf[KDF_ARGON2_KEY_SALT] length] != 32 ) {
            @throw [NSException exceptionWithName:@"CryptoException" reason:@"Argon2 salt not 12 bytes" userInfo:nil];
        }
    }
    
}

+(void) getDefaultKDFParameters:(VariantDictionary *)kdf uuid:(UUID*)uuid {
    
    [kdf addObject:[uuid getData] forKey:KDF_KEY_UUID_BYTES objtype:VARIANT_DICT_TYPE_BYTEARRAY];
    if( [uuid isEqual:[UUID getAES_KDFUUID]] ) {
        [kdf addObject:[Utils randomBytes:32] forKey:KDF_AES_KEY_SEED objtype:VARIANT_DICT_TYPE_BYTEARRAY];
        [kdf addObject:[[NSNumber alloc] initWithUnsignedLong:DEFAULT_AES_TRANSFORMATION_ROUNDS] forKey:KDF_AES_KEY_ROUNDS objtype:VARIANT_DICT_TYPE_UINT64];

    } else if( [uuid isEqual:[UUID getArgon2UUID]] ) {
        [kdf addObject:[[NSNumber alloc] initWithUnsignedLongLong:DEFAULT_ARGON2_ITERATIONS] forKey:KDF_ARGON2_KEY_ITERATIONS objtype:VARIANT_DICT_TYPE_UINT64];
        [kdf addObject:[[NSNumber alloc] initWithUnsignedLongLong:DEFAULT_ARGON2_MEMORY] forKey:KDF_ARGON2_KEY_MEMORY objtype:VARIANT_DICT_TYPE_UINT64];
        [kdf addObject:[[NSNumber alloc] initWithUnsignedInt:DEFAULT_ARGON2_PARALLELISM] forKey:KDF_ARGON2_KEY_PARALLELISM objtype:VARIANT_DICT_TYPE_UINT32];
        [kdf addObject:[[NSNumber alloc] initWithUnsignedInt:DEFAULT_ARGON2_VERSION] forKey:KDF_ARGON2_KEY_VERSION objtype:VARIANT_DICT_TYPE_UINT32];
        [kdf addObject:[Utils randomBytes:32] forKey:KDF_ARGON2_KEY_SALT objtype:VARIANT_DICT_TYPE_BYTEARRAY];

    } else {
        @throw [NSException exceptionWithName:@"CryptoException" reason:@"Unknown Algorithm" userInfo:nil];
    }
}

- (void)createMasterKeyV3:(uint8_t *)masterKey {
    if (password != nil && keyFile == nil) {
        // Hash the password into the master key
        NSData *passwordData = [password dataUsingEncoding:passswordEncoding];
        CC_SHA256(passwordData.bytes, (CC_LONG)passwordData.length, masterKey);
    } else if (password == nil && keyFile != nil) {
        // Get the bytes from the keyfile
        NSData *keyFileData = [self loadKeyFileV3:keyFile];
        if (keyFileData == nil) {
            @throw [NSException exceptionWithName:@"IOException" reason:@"Failed to load keyfile" userInfo:nil];
        }

        [keyFileData getBytes:masterKey length:32];
    } else {
        // Hash the password
        uint8_t passwordHash[32];
        NSData *passwordData = [password dataUsingEncoding:passswordEncoding];
        CC_SHA256(passwordData.bytes, (CC_LONG)passwordData.length, passwordHash);

        // Get the bytes from the keyfile
        NSData *keyFileData = [self loadKeyFileV3:keyFile];
        if (keyFileData == nil) {
            @throw [NSException exceptionWithName:@"IOException" reason:@"Failed to load keyfile" userInfo:nil];
        }

        // Hash the password and keyfile into the master key
        CC_SHA256_CTX ctx;
        CC_SHA256_Init(&ctx);
        CC_SHA256_Update(&ctx, passwordHash, 32);
        CC_SHA256_Update(&ctx, keyFileData.bytes, 32);
        CC_SHA256_Final(masterKey, &ctx);
    }
}

- (void)createMasterKeyV4:(uint8_t *)masterKey {
    // Initialize the master hash
    CC_SHA256_CTX ctx;
    CC_SHA256_Init(&ctx);

    // Add the password to the master key if it was supplied
    if (password != nil) {
        // Get the bytes from the password using the supplied encoding
        NSData *passwordData = [password dataUsingEncoding:passswordEncoding];

        // Hash the password
        uint8_t hash[32];
        CC_SHA256(passwordData.bytes, (CC_LONG)passwordData.length, hash);

        // Add the password hash to the master hash
        CC_SHA256_Update(&ctx, hash, 32);
    }

    // Add the keyfile to the master key if it was supplied
    if (keyFile != nil) {
        // Get the bytes from the keyfile
        NSData *keyFileData = [self loadKeyFileV4:keyFile];
        if (keyFileData == nil) {
            @throw [NSException exceptionWithName:@"IOException" reason:@"Failed to load keyfile" userInfo:nil];
        }

        // Add the keyfile hash to the master hash
        CC_SHA256_Update(&ctx, keyFileData.bytes, (CC_LONG)keyFileData.length);
    }

    // Finish the hash into the master key
    CC_SHA256_Final(masterKey, &ctx);
}

- (NSData*)createyKDBX4:(NSData *)finalKey {
    uint8_t key64[65];
    
    for( int i=0; i<65; ++i ) key64[i] = 0;
    memcpy( &key64[31], finalKey.bytes, 32 );
    key64[64] = 1;
    
    // Hash the extended cipher key
    uint8_t hash[32];
    CC_SHA512(key64, 64, hash);
    
    return [[NSData alloc] initWithBytes:hash length:32];
}

- (NSData*)loadKeyFileV3:(NSString*)filename {
    // Open the keyfile
    NSFileHandle *fh = [NSFileHandle fileHandleForReadingAtPath:filename];
    if (fh == nil) {
        return nil;
    }

    // Get the size of the keyfile
    unsigned long long fileSize = [fh seekToEndOfFile];
    [fh seekToFileOffset:0];

    NSData *data = nil;
    if (fileSize == 32) {
        // Load the binary key directly from the file
        data = [self loadBinKeyFile32:fh];
    } else if (fileSize == 64) {
        // Try and load the hex encoded key from the file
        data = [self loadHexKeyFile64:fh];
    }

    if (data == nil) {
        // The hex encoded file failed to load, so try and hash the file
        [fh seekToFileOffset:0];
        data = [self loadHashKeyFile:fh];
    }

    if (data == nil) {
        // The hex encoded file failed to load, so try and hash the file
        [fh seekToFileOffset:0];
        data = [self loadHashKeyFile:fh];
    }

    [fh closeFile];

    return data;
}

- (NSData*)loadKeyFileV4:(NSString*)filename {
    // Try and load a 2.x XML keyfile first
    @try {
        return [self loadXmlKeyFile:filename];
    } @catch (NSException *e) {
        // Ignore the exception and try and load the file through a different mechanism    NSData *data = nil;
    }

    return [self loadKeyFileV3:filename];
}

- (NSData*)loadXmlKeyFile:(NSString*)filename {
    NSString *xmlString = [NSString stringWithContentsOfFile:filename encoding:NSUTF8StringEncoding error:nil];
    if (xmlString == nil) {
        @throw [NSException exceptionWithName:@"IOException" reason:@"Failed to open keyfile" userInfo:nil];
    }

    DDXMLDocument *document = [[DDXMLDocument alloc] initWithXMLString:xmlString options:0 error:nil];
    if (document == nil) {
        @throw [NSException exceptionWithName:@"ParseError" reason:@"Failed to parse keyfile" userInfo:nil];
    }

    // Get the root document element
    DDXMLElement *rootElement = [document rootElement];

    DDXMLElement *keyElement = [rootElement elementForName:@"Key"];
    if (keyElement == nil) {
        @throw [NSException exceptionWithName:@"ParseError" reason:@"Failed to parse keyfile" userInfo:nil];
    }

    DDXMLElement *dataElement = [keyElement elementForName:@"Data"];
    if (dataElement == nil) {
        @throw [NSException exceptionWithName:@"ParseError" reason:@"Failed to parse keyfile" userInfo:nil];
    }

    NSString *dataString = [dataElement stringValue];
    if (dataString == nil) {
        @throw [NSException exceptionWithName:@"ParseError" reason:@"Failed to parse keyfile" userInfo:nil];
    }

    return [Base64 decode:[dataString dataUsingEncoding:NSASCIIStringEncoding]];
}

- (NSData*)loadBinKeyFile32:(NSFileHandle *)fh {
    return [fh readDataOfLength:32];
}

- (NSData*)loadHexKeyFile64:(NSFileHandle *)fh {
    uint8_t buffer[32];
    int value1;
    int value2;

    NSData *data = [fh readDataOfLength:64];
    if (data == nil) {
        return nil;
    }

    const char *ptr = data.bytes;
    for (int i = 0; i < 32; i++) {
        if ((value1 = hex2dec(ptr[i * 2])) == -1) {
            return nil;
        }
        if ((value2 = hex2dec(ptr[i * 2 + 1])) == -1) {
            return nil;
        }

        buffer[i] = value1 << 4 | value2;
    }

    return [NSData dataWithBytes:buffer length:32];
}

- (NSData*)loadHashKeyFile:(NSFileHandle*)fh {
    uint8_t buffer[32];
    NSData *data;

    CC_SHA256_CTX ctx;
    CC_SHA256_Init(&ctx);

    while (TRUE) {
        data = [fh readDataOfLength:2048];
        if (data.length == 0) {
            break;
        }
        CC_SHA256_Update(&ctx, data.bytes, (CC_LONG)data.length);
    }

    CC_SHA256_Final(buffer, &ctx);

    return [NSData dataWithBytes:buffer length:32];
}

int hex2dec(char c) {
    if ((c >= '0') && (c <= '9')) {
        return c - '0';
    } else if ((c >= 'a') && (c <= 'f')) {
        return c - 'a' + 10;
    } else if ((c >= 'A') && (c <= 'F')) {
        return c - 'A' + 10;
    } else {
        return -1;
    }
}

@end
