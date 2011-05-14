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

#import "TextFieldCell.h"
#import <UIKit/UIPasteboard.h>

@implementation TextFieldCell

@synthesize textField;

- (id)initWithParent:(UITableView*)parent {
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    if (self) {
        // Initialization code
        tableView = [parent retain];
        
        self.selectionStyle = UITableViewCellSelectionStyleNone;

        textField = [[UITextField alloc] initWithFrame:CGRectZero];
        textField.delegate = self;
        textField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        textField.textColor = [UIColor colorWithRed:.285 green:.376 blue:.541 alpha:1];
        textField.font = [UIFont systemFontOfSize:16];
        textField.returnKeyType = UIReturnKeyDone;
        [self addSubview:textField];
        
        tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapPressed)];
        [textField addGestureRecognizer:tapGesture];
    }
    return self;
}

- (void)dealloc {
    [textField release];
    [tapGesture release];
    [tableView release];
    [actionSheet release];
    [super dealloc];
}

- (void)dismissActionSheet {
    [actionSheet dismissWithClickedButtonIndex:actionSheet.cancelButtonIndex animated:NO];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGRect rect = self.contentView.frame;

    textField.frame = CGRectMake(rect.origin.x + 110, rect.origin.y, rect.size.width - 120, rect.size.height);
}

- (void)tapPressed {
    if (actionSheet != nil) {
        [actionSheet release];
    }
    actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Copy", @"Edit", nil];
    [actionSheet showInView:self.window];
}

- (void)actionSheet:(UIActionSheet*)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    switch (buttonIndex) {
        case 0: {
            UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
            pasteboard.string = textField.text;
            break;
        }

        case 1: {
            [textField becomeFirstResponder];
            break;
        }

        default:
            break;
    }
}

- (void)textFieldDidBeginEditing:(UITextField *)field {
    CGRect rect = [field convertRect:field.frame toView:tableView];
    CGFloat y = rect.origin.y - 12;
    if (y != tableView.contentOffset.y) {
        [tableView setContentOffset:CGPointMake(0.0, y) animated:YES];
    }
}

- (void)textFieldDidEndEditing:(UITextField *)field {
    // Clear all the extra gesture recognizers
    for (UIGestureRecognizer *gestureRecognizer in field.gestureRecognizers) {
        if (gestureRecognizer != tapGesture) {
            [field removeGestureRecognizer:gestureRecognizer];
        }
    }
}

- (BOOL)textFieldShouldReturn:(UITextField*)field {
    // Hide the keyboard
    [field resignFirstResponder];
        
    return YES;
}

@end
