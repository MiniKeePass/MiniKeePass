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
#import "MiniKeePassAppDelegate.h"

#define IMAGE_SIZE  24.0f
#define MIN_SPACING 10.5f

@interface ImageSelectionView () {
    NSMutableArray *imageViews;
    UIImageView *selectedImageView;
    CGFloat spacing;
    NSInteger imagesPerRow;
}
@end

@implementation ImageSelectionView

- (id)init {
    self = [super init];

    if (self) {
        // Get the application delegate
        MiniKeePassAppDelegate *appDelegate = (MiniKeePassAppDelegate*)[[UIApplication sharedApplication] delegate];
        
        // Load the images
        imageViews = [[NSMutableArray alloc] initWithCapacity:NUM_IMAGES];
        for (int i = 0; i < NUM_IMAGES; i++) {
            UIImage *image = [appDelegate loadImage:i];
                
            UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
            [self addSubview:imageView];                
            [imageViews addObject:imageView];
            [imageView release];
        }
        
        UIImage *selectedImage = [UIImage imageNamed:@"checkmark"];
        selectedImageView = [[UIImageView alloc] initWithImage:selectedImage];
        [self addSubview:selectedImageView];

        UITapGestureRecognizer *tapGestureRecgonizer = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                               action:@selector(handleTapGesture:)];
        [self addGestureRecognizer:tapGestureRecgonizer];
        [tapGestureRecgonizer release];
    }
    return self;
}

- (void)dealloc {
    [imageViews release];
    [selectedImageView release];
    [super dealloc];
}

- (void)layoutSubviews {
    UIScrollView *scrollView = (UIScrollView *)self.superview;

    // Compute the number of images per row as well as the spacing
    imagesPerRow = self.bounds.size.width / (IMAGE_SIZE + 2 * MIN_SPACING);
    spacing = ((self.bounds.size.width / imagesPerRow) - IMAGE_SIZE) / 2.0f;

    // Layout the images
    int numberOfRows = 0;
    CGRect imageFrame = CGRectMake(spacing, spacing, IMAGE_SIZE, IMAGE_SIZE);
    for (int i = 0; i < NUM_IMAGES; i += imagesPerRow) {
        numberOfRows++;
        for (int j = 0; j < imagesPerRow; j++) {
            if (i + j >= NUM_IMAGES) {
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
    self.selectedImageIndex = _selectedImageIndex;

    // Update the height of the frame based on the new layout
    CGRect newFrame = self.frame;
    newFrame.size.height = numberOfRows * (IMAGE_SIZE + 2 * spacing);
    self.frame = newFrame;
    
    scrollView.contentSize = newFrame.size;
}

- (void)setSelectedImageIndex:(NSUInteger)selectedImageIndex {
    if (selectedImageIndex >= NUM_IMAGES) {
        return;
    }
    
    _selectedImageIndex = selectedImageIndex;

    // Update the selected image view frame if we know how many images there are per row
    if (imagesPerRow > 0) {
        NSUInteger row = _selectedImageIndex / imagesPerRow;
        NSUInteger col = _selectedImageIndex - (row * imagesPerRow);

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

    self.selectedImageIndex = index;

    // Notify the delegate
    if ([_delegate respondsToSelector:@selector(imageSelectionView:selectedImageIndex:)]) {
        [_delegate imageSelectionView:self selectedImageIndex:_selectedImageIndex];
        
    }
}

@end
