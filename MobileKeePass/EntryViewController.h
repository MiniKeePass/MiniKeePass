//
//  EntryViewController2.h
//  MobileKeePass
//
//  Created by Jason Rush on 5/1/11.
//  Copyright 2011 Self. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TextFieldCell.h"
#import "UrlFieldCell.h"
#import "TextViewCell.h"
#import "PasswordFieldCell.h"
#import "Database.h"

@interface EntryViewController : UITableViewController <UITextFieldDelegate, UITextViewDelegate> {
    TextFieldCell *titleCell;
    UrlFieldCell *urlCell;
    TextFieldCell *usernameCell;
    PasswordFieldCell *passwordCell;
    TextViewCell *commentsCell;
    CGFloat originalHeight;

    Entry *entry;
}

@property (nonatomic, retain) Entry *entry;

- (void)cancelPressed:(id)sender;
- (void)savePressed:(id)sender;

@end
