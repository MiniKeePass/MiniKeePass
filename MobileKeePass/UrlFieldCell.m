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

#import "UrlFieldCell.h"

@implementation UrlFieldCell

- (id)initWithParent:(UITableView *)parent {
    self = [super initWithParent:parent];
    if (self) {
        // Initialization code
        textField.textColor = [UIColor blueColor];
        textField.autocorrectionType = UITextAutocorrectionTypeNo;
        textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        textField.keyboardType = UIKeyboardTypeURL;
    }
    return self;
}

- (void)tapPressed {
    if (actionSheet != nil) {
        [actionSheet release];
    }
    actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Open", @"Copy", @"Edit", nil];
    [actionSheet showInView:self.window];
}

- (void)actionSheet:(UIActionSheet*)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    switch (buttonIndex) {
        case 0: {
            NSString *text = textField.text;

            NSURL *url = [NSURL URLWithString:text];
            if (url.scheme == nil) {
                url = [NSURL URLWithString:[@"http://" stringByAppendingString:text]];
            }

            [[UIApplication sharedApplication] openURL:url];
            break;
        }

        case 1: {
            UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
            pasteboard.string = textField.text;
            break;
        }

        case 2: {
            [textField becomeFirstResponder];
            break;
        }

        default:
            break;
    }
}

@end
