/*
 * Copyright 2011-2013 Jason Rush and John Flanagan. All rights reserved.
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

#import "ImageSelectionViewController.h"

@implementation ImageSelectionViewController

@synthesize imageSelectionView = _imageSelectionView;

- (id)init {
    self = [super init];
    if (self) {
        self.title = NSLocalizedString(@"Images", nil);

        _imageSelectionView = [[ImageSelectionView alloc] init];
        _imageSelectionView.autoresizingMask = UIViewAutoresizingFlexibleWidth;

        UIScrollView *scrollView = [[UIScrollView alloc] init];
        scrollView.backgroundColor = [UIColor whiteColor];
        scrollView.alwaysBounceHorizontal = NO;
        [scrollView addSubview:_imageSelectionView];
        self.view = scrollView;
        [scrollView release];
    }
    return self;
}

- (void)dealloc {
    [_imageSelectionView release];
    [super dealloc];
}

- (ImageSelectionView *)imageSelectionView {
    return _imageSelectionView;
}

@end
