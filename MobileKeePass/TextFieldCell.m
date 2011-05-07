//
//  TextFieldCell.m
//  MobileKeePass
//
//  Created by Jason Rush on 5/1/11.
//  Copyright 2011 Self. All rights reserved.
//

#import "TextFieldCell.h"
#import <UIKit/UIPasteboard.h>
#import "EntryViewController.h"

@implementation TextFieldCell

@synthesize label;
@synthesize textField;

- (id)initWithParent:(UITableView*)parent {
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    if (self) {
        // Initialization code
        tableView = [parent retain];
        
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        label = [[UILabel alloc] initWithFrame:CGRectZero];
        label.textAlignment = UITextAlignmentRight;
        label.backgroundColor = [UIColor clearColor];
        label.textColor = [UIColor colorWithRed:.285 green:.376 blue:.541 alpha:1];
        label.font = [UIFont fontWithName:@"Helvetica" size:12];
        [self addSubview:label];
        
        textField = [[UITextField alloc] initWithFrame:CGRectZero];
        textField.delegate = self;
        textField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        textField.font = [UIFont systemFontOfSize:16];
        textField.returnKeyType = UIReturnKeyDone;
        [self addSubview:textField];
        
        tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapPressed)];
        [textField addGestureRecognizer:tapGesture];
    }
    return self;
}

- (void)dealloc {
    [label release];
    [textField release];
    [tapGesture release];
    [tableView release];
    [super dealloc];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGRect rect = self.contentView.frame;

    label.frame = CGRectMake(rect.origin.x, rect.origin.y, 80, rect.size.height);
    textField.frame = CGRectMake(rect.origin.x+95, rect.origin.y, rect.size.width-110, rect.size.height);
}

- (void)tapPressed {
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Copy", @"Edit", nil];
    [actionSheet showInView:self.window];
    [actionSheet release];
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
