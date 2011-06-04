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

@protocol StringEntryControllerDelegate;

@interface StringEntryController : UITableViewController <UITextFieldDelegate> {
    UITextField *textField;
    UIButton *okButton;
    UIButton *cancelButton;
    UILabel *statusLabel;

    NSString *entryTitle;
    BOOL secureTextEntry;
    NSString *placeholderText;
    NSString *string;

    id<StringEntryControllerDelegate> delegate;
}

@property (nonatomic, retain) UILabel *statusLabel;
@property (nonatomic, copy) NSString *entryTitle;
@property (nonatomic, assign) BOOL secureTextEntry;
@property (nonatomic, copy) NSString *placeholderText;
@property (nonatomic, copy) NSString *string;

@property (nonatomic, retain) id<StringEntryControllerDelegate> delegate;

@end

@protocol StringEntryControllerDelegate <NSObject>
- (void)stringEntryController:(StringEntryController*)controller stringEntered:(NSString*)string;
- (void)stringEntryControllerCancelButtonPressed:(StringEntryController*)controller;
@end
