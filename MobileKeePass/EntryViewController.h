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
#import "TextFieldCell.h"
#import "UrlFieldCell.h"
#import "TextViewCell.h"
#import "PasswordFieldCell.h"
#import "KdbLib.h"

@interface EntryViewController : UITableViewController <UITextFieldDelegate, UITextViewDelegate, UIActionSheetDelegate> {
    TextFieldCell *titleCell;
    UrlFieldCell *urlCell;
    TextFieldCell *usernameCell;
    PasswordFieldCell *passwordCell;
    TextViewCell *commentsCell;
    CGFloat originalHeight;

    id<KdbEntry> entry;
}

@property (nonatomic, retain) id<KdbEntry> entry;

@end
