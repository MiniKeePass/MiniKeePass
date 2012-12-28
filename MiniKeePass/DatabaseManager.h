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
#import "FormViewController.h"

typedef NS_ENUM(NSInteger, DatabaseType) {
    DatabaseTypeLocal,
    DatabaseTypeDropbox
};

@interface DatabaseFile : NSObject
@property (nonatomic, assign) DatabaseType type;
@property (nonatomic, copy) NSString *path;
@property (nonatomic, retain) NSDate *modificationDate;
@property (nonatomic, readonly) NSString *filename;

+ (DatabaseFile*)databaseWithType:(DatabaseType)type andPath:(NSString *)path;
+ (DatabaseFile*)databaseWithType:(DatabaseType)type path:(NSString *)path andModificationDate:(NSDate*)date;

@end

@interface DatabaseManager : NSObject <FormViewControllerDelegate>

@property (nonatomic, retain) DatabaseFile *selectedDatabaseFile;
@property (nonatomic) BOOL animated;

+ (DatabaseManager*)sharedInstance;
- (void)openDatabaseDocument:(DatabaseFile*)document animated:(BOOL)newAnimated;

@end
