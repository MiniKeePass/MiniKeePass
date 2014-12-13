/*
 * Copyright 2011-2014 Jason Rush and John Flanagan. All rights reserved.
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

#import "LockViewController.h"
#import "VersionUtils.h"

@interface LockViewController ()

@end

@implementation LockViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    UIImageView *imageView = [[UIImageView alloc] initWithFrame:self.view.frame];
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7")) {
        imageView.image = [[UIImage imageNamed:@"stretchme-7"] resizableImageWithCapInsets:UIEdgeInsetsMake(65, 0, 45, 0)];
    } else {
        imageView.image = [[UIImage imageNamed:@"stretchme"] resizableImageWithCapInsets:UIEdgeInsetsMake(44, 0, 44, 0)];
    }

    self.view = imageView;
}

@end
