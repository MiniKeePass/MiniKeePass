//
//  Password.m
//  KeePass2
//
//  Created by Qiang Yu on 1/5/10.
//  Copyright 2010 Qiang Yu. All rights reserved.
//

#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonCryptor.h>

#import "KdbPassword.h"
#import "DDXML.h"
#import "DDXMLElementAdditions.h"
#import "Base64.h"

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
    CCCryptorCreate(kCCEncrypt, kCCAlgorithmAES128, kCCOptionECBMode, transformSeed.bytes, kCCKeySizeAES256, nil, &cryptorRef);

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
