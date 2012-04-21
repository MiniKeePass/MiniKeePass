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

#import "ImagesViewController.h"
#import "MiniKeePassAppDelegate.h"

#define IMAGES_PER_ROW 7
#define SIZE 24
#define HORIZONTAL_SPACING 10.5
#define VERTICAL_SPACING 10.5

@implementation ImagesViewController

@synthesize delegate;

- (id)init {
    self = [super init];
    if (self) {
        // Get the application delegate
        MiniKeePassAppDelegate *appDelegate = (MiniKeePassAppDelegate*)[[UIApplication sharedApplication] delegate];
        
        imagesView = [[UIView alloc] init];
        
        CGRect frame = CGRectMake(HORIZONTAL_SPACING, VERTICAL_SPACING, SIZE, SIZE);
        
        // Load the images
        imageViews = [[NSMutableArray alloc] initWithCapacity:NUM_IMAGES];
        for (NSUInteger index = 0; index < NUM_IMAGES; index += IMAGES_PER_ROW) {
            for (int i = 0; i < IMAGES_PER_ROW; i++) {
                UIImage *image = [appDelegate loadImage:index + i];
                
                UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
                imageView.frame = frame;
                [imagesView addSubview:imageView];
                
                [imageViews addObject:imageView];
                
                [imageView release];
                
                frame.origin.x += SIZE + 2 * HORIZONTAL_SPACING;
            }
            
            frame.origin.x = HORIZONTAL_SPACING;
            frame.origin.y += SIZE + 2 * VERTICAL_SPACING; 
        }
        
        UIImage *selectedImage = [UIImage imageNamed:@"checkmark"];
        selectedImageView = [[UIImageView alloc] initWithImage:selectedImage];
        [imagesView addSubview:selectedImageView];
        
        [self setSelectedImage:0];
        
        UIScrollView *scrollView = [[UIScrollView alloc] init];
        scrollView.backgroundColor = [UIColor whiteColor];
        scrollView.alwaysBounceHorizontal = NO;
        scrollView.contentSize = CGSizeMake(IMAGES_PER_ROW * (SIZE + 2 * HORIZONTAL_SPACING), ceil(((CGFloat)NUM_IMAGES) / IMAGES_PER_ROW) * (SIZE + 2 * VERTICAL_SPACING));
        [scrollView addSubview:imagesView];
        
        UIGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(imageSelected:)];
        [scrollView addGestureRecognizer:gestureRecognizer];
        [gestureRecognizer release];
        
        self.view = scrollView;

        [scrollView release];
    }
    return self;
}

- (void)dealloc {
    [imagesView release];
    [imageViews release];
    [selectedImageView release];
    [delegate release];
    [super dealloc];
}

- (void)setSelectedImage:(NSUInteger)index {
    if (index >= NUM_IMAGES) {
        return;
    }
    
    NSUInteger row = index / IMAGES_PER_ROW;
    NSUInteger col = index - (row * IMAGES_PER_ROW);
    
    CGSize size = selectedImageView.image.size;
    CGRect frame = CGRectMake((col + 1) * (SIZE + 2 * HORIZONTAL_SPACING) - size.width, (row + 1) * (SIZE + 2 * VERTICAL_SPACING) - size.height, size.width, size.height);
    selectedImageView.frame = frame;
}

- (void)imageSelected:(UIGestureRecognizer*)gestureRecognizer {
    CGPoint point = [gestureRecognizer locationInView:imagesView];
    NSUInteger col = point.x / (SIZE + 2 * HORIZONTAL_SPACING);
    NSUInteger row = point.y / (SIZE + 2 * VERTICAL_SPACING);
    
    NSUInteger index = row * IMAGES_PER_ROW + col;
    [self setSelectedImage:index];
    
    if ([delegate respondsToSelector:@selector(imagesViewController:imageSelected:)]) {
        [delegate imagesViewController:self imageSelected:index];
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return YES;
}

@end
