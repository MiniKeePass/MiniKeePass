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
#import "InfoBar.h"

@protocol FormViewControllerDelegate;

@interface FormViewController : UITableViewController {
    NSArray *controls;
    NSString *headerTitle;
    NSString *footerTitle;
    
    InfoBar *infoBar;
    
    id<FormViewControllerDelegate> delegate;
}

@property (nonatomic, retain) NSArray *controls;
@property (nonatomic, copy) NSString *headerTitle;
@property (nonatomic, copy) NSString *footerTitle;

@property (nonatomic, retain) id<FormViewControllerDelegate> delegate;

- (void)showErrorMessage:(NSString*)message;

@end

typedef enum {
    FormViewControllerButtonCancel,
    FormViewControllerButtonOk
} FormViewControllerButton;

@protocol FormViewControllerDelegate <NSObject>
- (void)formViewController:(FormViewController *)controller button:(FormViewControllerButton)button;
@end
