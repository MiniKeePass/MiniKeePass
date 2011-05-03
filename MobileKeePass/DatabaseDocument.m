//
//  DatabaseDocument.m
//  MobileKeePass
//
//  Created by Jason Rush on 5/1/11.
//  Copyright 2011 Self. All rights reserved.
//

#import "DatabaseDocument.h"
#import "Kdb3.h"

@implementation DatabaseDocument

@synthesize database;
@synthesize filename;
@synthesize dirty;

- (id)init {
    self = [super init];
    if (self) {
        database = nil;
        filename = nil;
        dirty = NO;
    }
    return self;
}


- (void)dealloc {
    [database release];
    [filename release];
    [super dealloc];
}

- (enum DatabaseError)open:(NSString *)path password:(NSString *)password {
    [database release];
    [filename release];
    
    filename = [path retain];
    dirty = NO;
    database = [[Kdb3 alloc] init];
    
    return [database openDatabase:filename password:password];
}

- (enum DatabaseError)new:(NSString *)path password:(NSString *)passowrd {
    [database release];
    [filename release];
    
    filename = [path retain];
    dirty = NO;
    database = [[Kdb3 alloc] init];
    
    return [database newDatabase:filename password:passowrd];
}

- (enum DatabaseError)save {
    if (dirty) {
        dirty = NO;
        return [database saveDatabase:filename];
    }
    return NO_ERROR;
}

@end
