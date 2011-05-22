//
//  KdbWriterFactory.m
//  MobileKeePass
//
//  Created by Jason Rush on 5/21/11.
//  Copyright 2011 Self. All rights reserved.
//

#import "KdbWriterFactory.h"
#import "Kdb3Writer.h"
#import "Kdb4Writer.h"

@implementation KdbWriterFactory

+ (void)persist:(KdbTree*)tree file:(NSString*)filename withPassword:(NSString*)password {
    id<KdbWriter> writer;
    
    if ([tree isKindOfClass:[Kdb3Tree class]]) {
        writer = [[Kdb3Writer alloc] init];
    } else if ([tree isKindOfClass:[Kdb4Tree class]]) {
        writer = [[Kdb4Writer alloc] init];
    } else {
        @throw [NSException exceptionWithName:@"IllegalArgument" reason:@"IllegalArgument" userInfo:nil];
    }
    
    [writer persist:tree file:filename withPassword:password];
    [writer release];
}

@end
