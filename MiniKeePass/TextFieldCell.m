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
@synthesize textFieldCellDelegate;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        textField = [[UITextField alloc] init];
        textField.delegate = self;
        textField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        textField.textColor = [UIColor colorWithRed:.285 green:.376 blue:.541 alpha:1];
        textField.font = [UIFont systemFontOfSize:16];
        textField.returnKeyType = UIReturnKeyNext;
        textField.clearButtonMode = UITextFieldViewModeWhileEditing;
        [self addSubview:textField];
        
        tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapPressed)];
        [textField addGestureRecognizer:tapGesture];
        
        appDelegate = (MiniKeePassAppDelegate*)[[UIApplication sharedApplication] delegate];
    }
    return self;
}

- (void)dealloc {
    [textField release];
    [tapGesture release];
    [textFieldCellDelegate release];
    [super dealloc];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGRect rect = self.contentView.frame;
    
    textField.frame = CGRectMake(rect.origin.x + 110, rect.origin.y, rect.size.width - 120, rect.size.height);
}

- (void)tapPressed {
    if (self.textField.text == nil || [self.textField.text isEqualToString:@""]) {
        [textField becomeFirstResponder];
    } else {
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Copy", nil), NSLocalizedString(@"Edit", nil), nil];
        
        [appDelegate showActionSheet:actionSheet];
        [actionSheet release];
    }
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
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
    // Scroll to the top
    UITableView *tableView = (UITableView*)self.superview;
    [tableView scrollRectToVisible:self.frame animated:YES];
    
    tapGesture.enabled = NO;
}

- (void)textFieldDidEndEditing:(UITextField *)field {
    // Ensure our gesture recgonizer is on top
    [field removeGestureRecognizer:tapGesture];
    [field addGestureRecognizer:tapGesture];
    
    tapGesture.enabled = YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)field {
    if ([textFieldCellDelegate respondsToSelector:@selector(textFieldCellWillReturn:)]) {
        [textFieldCellDelegate textFieldCellWillReturn:self];
    }
    
    return NO;
}

@end
