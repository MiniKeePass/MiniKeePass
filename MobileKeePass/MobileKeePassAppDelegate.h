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
#import "GroupViewController.h"
#import "PinViewController.h"
#import "DatabaseDocument.h"

@interface MobileKeePassAppDelegate : NSObject <UIApplicationDelegate, PinViewControllerDelegate, UIActionSheetDelegate> {
    UIWindow *window;
    UINavigationController *navigationController;
    GroupViewController *groupViewController;
    
    UIImage *images[70];
    
    DatabaseDocument *databaseDocument;
}

@property (nonatomic, retain) DatabaseDocument *databaseDocument;

- (UIImage*)loadImage:(int)index;
- (void)closeDatabase;
- (void)openLastDatabase;

@end

