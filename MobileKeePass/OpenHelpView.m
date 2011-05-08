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
        
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(8, 0, 304, 400)];
        label.font = [UIFont systemFontOfSize:14];
        label.textColor = [UIColor darkTextColor];
        label.backgroundColor = [UIColor clearColor];
        label.numberOfLines = 0;
        label.lineBreakMode = UILineBreakModeWordWrap;
        label.text = @"You do not have any KeePass files available for MobileKeePass.\n\n"
            @"Follow these steps to add some files using iTunes:\n"
            @" * Connect your device to your computer and wait for iTunes to launch\n"
            @" * When iTunes appears, select your device and click the Apps tab\n"
            @" * Scroll down to the File Sharing table and select MobileKeePass from the list\n"
            @" * Click the Add button, select the KeePass file, and click Choose";
        [self addSubview:label];
        [label release];
    }
    return self;
}

- (void)dealloc {
    [super dealloc];
}

@end
