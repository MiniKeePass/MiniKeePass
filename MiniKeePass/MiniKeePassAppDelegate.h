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

#import <UIKit/UIKit.h>
#import "FilesViewController.h"
#import "PinViewController.h"
#import "DatabaseDocument.h"

#define NUM_IMAGES 69

@interface MiniKeePassAppDelegate : NSObject <UIApplicationDelegate, PinViewControllerDelegate, UIActionSheetDelegate> {
    UIWindow *window;
    UINavigationController *navigationController;
    UIActionSheet* myActionSheet;
    id<UIActionSheetDelegate> myActionSheetDelegate;
    
    DatabaseDocument *databaseDocument;
    NSString *fileToOpen;
    
    UIImage *images[NUM_IMAGES];
    
    BOOL backgroundSupported;
}

@property (nonatomic, readonly) UIWindow *window;
@property (nonatomic, retain) DatabaseDocument *databaseDocument;
@property (nonatomic, readonly) BOOL backgroundSupported;

- (void)closeDatabase;
- (void)deleteAllData;
- (UIImage*)loadImage:(NSUInteger)index;
- (void)showSettingsView;
- (void)dismissSettingsView;
- (void)showActionSheet:(UIActionSheet*)actionSheet;
- (void)dismissActionSheet;

@end