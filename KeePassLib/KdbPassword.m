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

@interface KdbPassword (PrivateMethods)
- (NSData*)loadKeyFile:(NSString*)filename;
- (NSData*)loadBinKeyFile32:(NSFileHandle*)fh;
- (NSData*)loadHexKeyFile64:(NSFileHandle*)fh;
- (NSData*)loadHashKeyFile:(NSFileHandle*)fh;
@end

int hex2dec(char c);

@implementation KdbPassword

- (id)initWithPassword:(NSString*)password encoding:(NSStringEncoding)encoding {
    self = [super init];
    if (self) {
        // Decode the string into bytes using the string encoding
        NSData *pass = [password dataUsingEncoding:encoding];
        
        // Hash the password
        uint8_t passwordKey[32];
        CC_SHA256(pass.bytes, pass.length, passwordKey);
        
        // Create the master key
        masterKey = [[NSData alloc] initWithBytes:passwordKey length:32];
    }
    return self;
}

- (id)initWithKeyfile:(NSString*)filename {
    self = [super init];
    if (self) {
        // Get the file hash
        masterKey = [self loadKeyFile:filename];
        if (masterKey == nil) {
            @throw [NSException exceptionWithName:@"IOException" reason:@"Failed to load keyfile" userInfo:nil];
        }
    }
    return self;
}

- (id)initWithPassword:(NSString*)password encoding:(NSStringEncoding)encoding keyfile:(NSString*)filename {
    self = [super init];
    if (self) {
        // Decode the string into bytes using the string encoding
        NSData *pass = [password dataUsingEncoding:encoding];
        
        // Hash the password
        uint8_t passwordKey[32];
        CC_SHA256(pass.bytes, pass.length, passwordKey);
        
        // Get the file hash
        NSData *fileKey = [self loadKeyFile:filename];
        if (fileKey == nil) {
            @throw [NSException exceptionWithName:@"IOException" reason:@"Failed to load keyfile" userInfo:nil];
        }
        
        // Combine the two
        uint8_t key[32];
        CC_SHA256_CTX ctx;
        CC_SHA256_Init(&ctx);
        CC_SHA256_Update(&ctx, passwordKey, 32);
        CC_SHA256_Update(&ctx, fileKey.bytes, 32);
        CC_SHA256_Final(key, &ctx);
        
        masterKey = [[NSData alloc] initWithBytes:key length:32];
    }
    return self;
}

- (NSData*)createFinalKeyForVersion:(uint8_t)version masterSeed:(NSData*)masterSeed transformSeed:(NSData*)transformSeed rounds:(uint64_t)rounds {
    uint8_t keyHash[32];
    
    memcpy(keyHash, masterKey.bytes, masterKey.length);
    
    if (version == 4) {
        CC_SHA256(keyHash, 32, keyHash);
    }
    
    // Step 1 transform the key
    CCCryptorRef cryptorRef;
    CCCryptorCreate(kCCEncrypt, kCCAlgorithmAES128, kCCOptionECBMode, transformSeed.bytes, kCCKeySizeAES256, nil, &cryptorRef);
    
    size_t tmp;
    for (int i = 0; i < rounds; i++) {
        CCCryptorUpdate(cryptorRef, keyHash, 32, keyHash, 32, &tmp);
    }
    
    CCCryptorRelease(cryptorRef);
    
    uint8_t transformed[32];
    CC_SHA256(keyHash, 32, transformed);
    
    // Step 2 hash the transform result
    CC_SHA256_CTX ctx;
    CC_SHA256_Init(&ctx);
    CC_SHA256_Update(&ctx, masterSeed.bytes, masterSeed.length);
    CC_SHA256_Update(&ctx, transformed, 32);
    
    uint8_t finalKey[32];
    CC_SHA256_Final(finalKey, &ctx);
    
    return [NSData dataWithBytes:finalKey length:32];
}

- (NSData*)loadKeyFile:(NSString*)filename {
    NSData *keyFile = nil;
    
    // Open the keyfile
    NSFileHandle *fh = [NSFileHandle fileHandleForReadingAtPath:filename];
    if (fh == nil) {
        return nil;
    }
    
    // Get the size of the keyfile
    unsigned long long fileSize = [fh seekToEndOfFile];
    [fh seekToFileOffset:0];
    
    if (fileSize == 32) {
        // Load the binary key directly from the file
        keyFile = [self loadBinKeyFile32:fh];
    } else if (fileSize == 64) {
        // Try and load the hex encoded key from the file
        keyFile = [self loadHexKeyFile64:fh];
    }
    
    if (keyFile == nil) {
        // The hex encoded file failed to load, so try and hash the file
        [fh seekToFileOffset:0];
        keyFile = [self loadHashKeyFile:fh];
    }
    
    [fh closeFile];
    if (keyFile == nil) {
        // The hex encoded file failed to load, so try and hash the file
        [fh seekToFileOffset:0];
        keyFile = [self loadHashKeyFile:fh];
    }
 
    return keyFile;
}

- (NSData*)loadBinKeyFile32:(NSFileHandle *)fh {
    return [fh readDataOfLength:32];
}

- (NSData*)loadHexKeyFile64:(NSFileHandle *)fh {
    uint8_t keyFile[32];
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
        
        keyFile[i] = value1 << 4 | value2;
    }
    
    return [NSData dataWithBytes:keyFile length:32];
}

- (NSData*)loadHashKeyFile:(NSFileHandle*)fh {
    uint8_t keyFile[32];
    NSData *data;
    
    CC_SHA256_CTX ctx;
    CC_SHA256_Init(&ctx);
    
    while (TRUE) {
        data = [fh readDataOfLength:2048];
        if (data.length == 0) {
            break;
        }
        CC_SHA256_Update(&ctx, data.bytes, data.length);
    }
    
    CC_SHA256_Final(keyFile, &ctx);
    
    return [NSData dataWithBytes:keyFile length:32];
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
