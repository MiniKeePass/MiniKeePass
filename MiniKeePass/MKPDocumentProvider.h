//
//  MKPDocumentProvider.h
//  MiniKeePass
//
//  Created by John on 12/18/12.
//  Copyright (c) 2012 Self. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MKPDocument.h"

@interface MKPDocumentProvider : NSObject

@property (nonatomic, readonly) NSArray *documents;
@property (nonatomic, readonly) NSArray *keyFiles;

- (void)updateFiles;

- (void)openDocument:(MKPDocument *)document;
- (void)openDocumentAtIndex:(NSInteger)index;

- (void)deleteDocument:(MKPDocument *)document;
- (void)deleteDocumentAtIndex:(NSInteger)index;

- (void)deleteKeyFile:(MKPDocument *)document;
- (void)deleteKeyFileAtIndex:(NSInteger)index;

@end
