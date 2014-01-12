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

#import "ImageSelectionView.h"
#import "ImageFactory.h"

#define IMAGE_SIZE  24.0f
#define MIN_SPACING 10.5f

@interface ImageSelectionView () {
    NSArray *kdbImages;
    NSUInteger numImages;
    NSMutableArray *imageViews;
    UIImageView *selectedImageView;
    CGFloat spacing;
    NSInteger imagesPerRow;
}

@property (nonatomic, assign) NSUInteger selectedIndex;
@end

@implementation ImageSelectionView

- (id)init {
    self = [super init];

    if (self) {
        // Get the application delegate
        ImageFactory *imageFactory = [ImageFactory sharedInstance];
        kdbImages = imageFactory.kdbImages;
        numImages = [kdbImages count];

        // Create an image view for each image
        imageViews = [[NSMutableArray alloc] initWithCapacity:numImages];
        for (KdbImage *kdbImage in kdbImages) {
            UIImageView *imageView = [[UIImageView alloc] initWithImage:kdbImage.image];
            [self addSubview:imageView];
            [imageViews addObject:imageView];
        }
        
        UIImage *selectedImage = [UIImage imageNamed:@"checkmark"];
        selectedImageView = [[UIImageView alloc] initWithImage:selectedImage];
        [self addSubview:selectedImageView];

        UITapGestureRecognizer *tapGestureRecgonizer = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                               action:@selector(handleTapGesture:)];
        [self addGestureRecognizer:tapGestureRecgonizer];
    }
    return self;
}

- (void)layoutSubviews {
    UIScrollView *scrollView = (UIScrollView *)self.superview;

    // Compute the number of images per row as well as the spacing
    imagesPerRow = self.bounds.size.width / (IMAGE_SIZE + 2 * MIN_SPACING);
    spacing = ((self.bounds.size.width / imagesPerRow) - IMAGE_SIZE) / 2.0f;

    // Layout the images
    int numberOfRows = 0;
    CGRect imageFrame = CGRectMake(spacing, spacing, IMAGE_SIZE, IMAGE_SIZE);
    for (int i = 0; i < numImages; i += imagesPerRow) {
        numberOfRows++;
        for (int j = 0; j < imagesPerRow; j++) {
            if (i + j >= numImages) {
                break;
            }
            
            UIImageView *imageView = (UIImageView *)[imageViews objectAtIndex:i + j];
            imageView.frame = imageFrame;
            
            imageFrame.origin.x += IMAGE_SIZE + 2 * spacing;
        }
        
        imageFrame.origin.x = spacing;
        imageFrame.origin.y += IMAGE_SIZE + 2 * spacing;
    }

    // Re-select the image after layout
    self.selectedIndex = _selectedIndex;

    // Update the height of the frame based on the new layout
    CGRect newFrame = self.frame;
    newFrame.size.height = numberOfRows * (IMAGE_SIZE + 2 * spacing);
    self.frame = newFrame;
    
    scrollView.contentSize = newFrame.size;
}

- (void)setSelectedImage:(KdbImage *)selectedImage {
    self.selectedIndex = [kdbImages indexOfObject:selectedImage];
}

- (KdbImage *)selectedImage {
    return [kdbImages objectAtIndex:self.selectedIndex];
}

- (void)setSelectedIndex:(NSUInteger)selectedIndex {
    if (selectedIndex >= numImages) {
        return;
    }
    
    _selectedIndex = selectedIndex;

    // Update the selected image view frame if we know how many images there are per row
    if (imagesPerRow > 0) {
        NSUInteger row = self.selectedIndex / imagesPerRow;
        NSUInteger col = self.selectedIndex - (row * imagesPerRow);

        CGSize size = selectedImageView.image.size;
        CGRect frame = CGRectMake((col + 1) * (IMAGE_SIZE + 2 * spacing) - size.width,
                                  (row + 1) * (IMAGE_SIZE + 2 * spacing) - size.height,
                                  size.width, size.height);
        selectedImageView.frame = frame;
    }
}

- (void)handleTapGesture:(UIGestureRecognizer*)gestureRecognizer {
    CGPoint point = [gestureRecognizer locationInView:self];

    // Convert the point to row/col
    NSUInteger col = point.x / (IMAGE_SIZE + 2 * spacing);
    NSUInteger row = point.y / (IMAGE_SIZE + 2 * spacing);

    // Convert the row/col to an index
    NSUInteger index = row * imagesPerRow + col;

    self.selectedIndex = index;

    // Notify the delegate
    if ([_delegate respondsToSelector:@selector(imageSelectionView:selectedKdbImage:)]) {
        KdbImage *kdbImage = [kdbImages objectAtIndex:self.selectedIndex];
        [_delegate imageSelectionView:self selectedKdbImage:kdbImage];
        
    }
}

@end
