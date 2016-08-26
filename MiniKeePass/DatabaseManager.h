/*
 * Copyright 2011-2012 Jason Rush and John Flanagan. All rights reserved.
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

@interface DatabaseManager : NSObject

/// A string containing the name of the KeePass DatabaseDocument to be managed
@property (nonatomic, copy) NSString *selectedFilename;

/// Create a DatabaseManager instance
+ (DatabaseManager*)sharedInstance;

- (NSArray *)getDatabases;
- (NSArray *)getKeyFiles;
- (NSURL *)getFileUrl:(NSString *)filename;
- (NSDate *)getFileLastModificationDate:(NSURL *)url;
- (void)deleteFile:(NSString *)filename;
- (void)newDatabase:(NSURL *)url password:(NSString *)password version:(NSInteger)version;
- (void)renameDatabase:(NSURL *)originalUrl newUrl:(NSURL *)newUrl;

/// Open the specified KeePass DatabaseDocument
/// @param path Path to the chosen KeePass DatabaseDocument
/// @param animated Animate the ViewController transition
- (void)openDatabaseDocument:(NSString*)path animated:(BOOL)newAnimated;

@end
