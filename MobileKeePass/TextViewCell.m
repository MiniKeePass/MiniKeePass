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

#import "TextViewCell.h"

@implementation TextViewCell

@synthesize textView;

- (id)initWithParent:(UITableView*)parent {
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    if (self) {
        // Initialization code
        tableView = [parent retain];
        
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        textView = [[UITextView alloc] initWithFrame:CGRectZero];
        textView.font = [UIFont systemFontOfSize:16];
        textView.contentSize = CGSizeMake(320, 150);
        textView.delegate = self;
        [self addSubview:textView];
    }
    return self;
}

- (void)dealloc {
    [textView release];
    [tableView release];
    [super dealloc];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGRect rect = self.contentView.frame;
    
    textView.frame = CGRectMake(rect.origin.x + 3, rect.origin.y + 3, rect.size.width - 6, rect.size.height - 6);
}

- (void)textViewDidBeginEditing:(UITextView *)view {    
    CGRect rect = [view convertRect:view.frame toView:tableView];
    CGFloat y = rect.origin.y - 44;
    if (y != tableView.contentOffset.y) {
        [tableView setContentOffset:CGPointMake(0.0, y) animated:YES];
    }
}

@end
