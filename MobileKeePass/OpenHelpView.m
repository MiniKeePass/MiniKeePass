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

#import "OpenHelpView.h"

@implementation OpenHelpView

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.backgroundColor = [UIColor groupTableViewBackgroundColor];
        
        UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"connect.png"]];
        imageView.frame = CGRectMake(94, 16, 131, 98);
        [self addSubview:imageView];
        [imageView release];
        
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 130, 320, 20)];
        label.text = @"Connect to iTunes";
        label.backgroundColor = [UIColor clearColor];
        label.textAlignment = UITextAlignmentCenter;
        [self addSubview:label];
        [label release];
        
        label = [[UILabel alloc] initWithFrame:CGRectMake(16, 166, 288, 234)];
        label.font = [UIFont systemFontOfSize:14];
        label.textColor = [UIColor darkTextColor];
        label.backgroundColor = [UIColor clearColor];
        label.numberOfLines = 0;
        label.lineBreakMode = UILineBreakModeWordWrap;
        label.text = @"You do not have any KeePass files available for MobileKeePass to open.\n\n"
            @"Steps for adding files using iTunes:\n"
            @" * Connect your device to your computer\n"
            @" * When iTunes appears select your device\n"
            @" * Click on the Apps tab\n"
            @" * Sroll down to File Sharing\n"
            @" * Select MobileKeePass from the list\n"
            @" * Click on the Add button and select a file\n";
        [self addSubview:label];
        [label release];
    }
    return self;
}

- (void)dealloc {
    [super dealloc];
}

@end
