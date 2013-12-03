//
//  KdbReaderFactory.m
//  KeePass2
//
//  Created by Qiang Yu on 3/8/10.
//  Copyright 2010 Qiang Yu. All rights reserved.
//

#import "KdbReaderFactory.h"
#import "Kdb3Reader.h"
#import "Kdb4Reader.h"
#import "DataInputStream.h"
#import "FileInputStream.h"

@implementation KdbReaderFactory

+ (KdbTree*)load:(NSString*)filename withPassword:(KdbPassword*)kdbPassword {
    FileInputStream *inputStream = [[FileInputStream alloc] initWithFilename:filename];
    uint32_t sig1 = [inputStream readInt32];
    sig1 = CFSwapInt32LittleToHost(sig1);
    
    uint32_t sig2 = [inputStream readInt32];
    sig2 = CFSwapInt32LittleToHost(sig2);
    
    id<KdbReader> reader;
    if (sig1 == KDB3_SIG1 && sig2 == KDB3_SIG2) {
        reader = [[Kdb3Reader alloc] init];
    } else if (sig1 == KDB4_SIG1 && sig2 == KDB4_SIG2) {
        reader = [[Kdb4Reader alloc] init];
    } else {
        @throw [NSException exceptionWithName:@"IOException" reason:@"Invalid file signature" userInfo:nil];
    }

    // Reset the input stream back to the beginning of the file
    [inputStream seek:0];
    
    KdbTree *tree = [reader load:inputStream withPassword:kdbPassword];
    
    return tree;
}

@end
