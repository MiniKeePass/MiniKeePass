/*
 * Copyright 2011-2012 Jason Rush and John Flanagan. All rights reserved.
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

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        textView = [[UITextView alloc] initWithFrame:CGRectZero];
        textView.font = [UIFont systemFontOfSize:16];
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

@end
