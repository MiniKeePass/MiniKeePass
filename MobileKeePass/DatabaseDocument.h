//
//  DatabaseDocument.h
//  MobileKeePass
//
//  Created by Jason Rush on 5/1/11.
//  Copyright 2011 Self. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Database.h"

@interface DatabaseDocument : NSObject {
    NSObject<Database> *database;
    NSString *filename;
    BOOL dirty;
}

@property (nonatomic, retain) NSObject<Database> *database;
@property (nonatomic, retain) NSString *filename;
@property (nonatomic) BOOL dirty;

- (enum DatabaseError)open:(NSString *)path password:(NSString *)password;
- (enum DatabaseError)new:(NSString *)path password:(NSString *)passowrd;
- (enum DatabaseError)save;

@end
