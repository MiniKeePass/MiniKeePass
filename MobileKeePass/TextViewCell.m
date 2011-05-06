//
//  TextViewCell.m
//  MobileKeePass
//
//  Created by Jason Rush on 5/1/11.
//  Copyright 2011 Self. All rights reserved.
//

#import "TextViewCell.h"

@implementation TextViewCell

@synthesize textView;

- (id)initWithParent:(UITableView*)parent {
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    if (self) {
        // Initialization code
        tableView = parent;
        
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        textView = [[UITextView alloc] initWithFrame:CGRectZero];
        textView.font = [UIFont systemFontOfSize:16];
        textView.contentSize = CGSizeMake(320, 150);
        textView.delegate = self;
        [self addSubview:textView];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGRect rect = self.contentView.frame;
    
    textView.frame = CGRectMake(rect.origin.x + 3, rect.origin.y + 3, rect.size.width - 6, rect.size.height - 6);
}

- (void)dealloc {
    [textView release];
    [super dealloc];
}

- (void)textViewDidBeginEditing:(UITextView *)view {    
    CGRect rect = [view convertRect:view.frame toView:tableView];
    CGFloat y = rect.origin.y - 12;
    if (y != tableView.contentOffset.y) {
        [tableView setContentOffset:CGPointMake(0.0, y) animated:YES];
    }
}

@end
