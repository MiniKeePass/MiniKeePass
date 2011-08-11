/*
 * Copyright 2011 Jason Rush and John Flanagan. All rights reserved.
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

#import <Foundation/Foundation.h>
#import "KdbLib.h"

@interface DatabaseDocument : NSObject {
    KdbTree *kdbTree;
    NSString *filename;
    BOOL dirty;
    
    KdbPassword *kdbPassword;
    
    UIDocumentInteractionController *documentInteractionController;
}

@property (nonatomic, retain) KdbTree *kdbTree;
@property (nonatomic, retain) NSString *filename;
@property (nonatomic) BOOL dirty;
@property (nonatomic, readonly) UIDocumentInteractionController *documentInteractionController;

- (void)open:(NSString*)newFilename password:(NSString*)password keyFile:(NSString*)keyFile;
- (void)save;
- (void)searchGroup:(KdbGroup*)group searchText:(NSString*)searchText results:(NSMutableArray*)results;

@end
