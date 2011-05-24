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

@implementation KdbReaderFactory

+ (KdbTree*)load:(NSString*)filename withPassword:(NSString*)password {
    // FIXME this is horribly broken
    KdbTree *tree = nil;
    
    DataInputStream *inputStream = [[DataInputStream alloc] initWithData:[NSData dataWithContentsOfFile:filename]];
    uint32_t sig1 = [inputStream readInt32];
    sig1 = CFSwapInt32LittleToHost(sig1);
    
    uint32_t sig2 = [inputStream readInt32];
    sig2 = CFSwapInt32LittleToHost(sig2);
    
    if (sig1 == KDB3_SIG1 && sig2 == KDB3_SIG2) {
        Kdb3Reader *reader = [[Kdb3Reader alloc] init];
        tree = [reader load:inputStream withPassword:password];
        [reader release];
    }
    
    [inputStream release];
    
    if (tree == nil) {
        @throw [NSException exceptionWithName:@"IOException" reason:@"Invalid file signature" userInfo:nil];
    }
    
    return tree;
}

@end
