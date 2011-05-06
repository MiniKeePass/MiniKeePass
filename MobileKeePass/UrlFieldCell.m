//
//  UrlFieldCell.m
//  MobileKeePass
//
//  Created by Jason Rush on 5/1/11.
//  Copyright 2011 Self. All rights reserved.
//

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
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Open", @"Copy", @"Edit", nil];
    [actionSheet showInView:self.window];
    [actionSheet release];
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
