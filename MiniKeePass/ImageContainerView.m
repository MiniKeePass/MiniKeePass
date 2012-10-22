//
//  ImageContainerView.m
//  MiniKeePass
//
//  Created by John Flanagan on 6/28/12.
//  Copyright (c) 2012 Self. All rights reserved.
//

#import "ImageContainerView.h"
#import "MiniKeePassAppDelegate.h"

//#define IMAGES_PER_ROW 7
#define SIZE 24
#define HORIZONTAL_SPACING 10.5
#define VERTICAL_SPACING 10.5

NSInteger imagesPerRow;
NSUInteger selectedImageIndex;

@implementation ImageContainerView

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];

    if (self) {
        imagesPerRow = self.frame.size.width / (SIZE + 2 * HORIZONTAL_SPACING);
        imageViews = [[NSMutableArray alloc] initWithCapacity:NUM_IMAGES];
        // Get the application delegate
        MiniKeePassAppDelegate *appDelegate = (MiniKeePassAppDelegate*)[[UIApplication sharedApplication] delegate];
        
        // Load the images
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
        
        [self setSelectedImage:0];
    }
    return self;
}

-(void)dealloc {
    [imageViews release];
    [selectedImageView release];
    [super dealloc];
}

- (void)layoutSubviews {
    UIScrollView *scrollView = (UIScrollView *)self.superview;
    self.frame = scrollView.frame;
    
    imagesPerRow = self.frame.size.width / (SIZE + 2 * HORIZONTAL_SPACING);
    int numberOfRows = 0;
    
    CGRect imageFrame = CGRectMake(HORIZONTAL_SPACING, VERTICAL_SPACING, SIZE, SIZE);
    
    // Load the images
    for (int i = 0; i < NUM_IMAGES; i += imagesPerRow) {
        numberOfRows++;
        for (int j = 0; j < imagesPerRow; j++) {
            if (i + j >= NUM_IMAGES) {
                break;
            }
            
            UIImageView *imageView = (UIImageView *)[imageViews objectAtIndex:i + j];
            imageView.frame = imageFrame;
            
            imageFrame.origin.x += SIZE + 2 * HORIZONTAL_SPACING;
        }
        
        imageFrame.origin.x = HORIZONTAL_SPACING;
        imageFrame.origin.y += SIZE + 2 * VERTICAL_SPACING;
    }
    
    [self setSelectedImage:selectedImageIndex];
    
    CGFloat newHeight = numberOfRows * (SIZE + 2 * VERTICAL_SPACING);
    
    CGRect newFrame = self.frame;
    newFrame.size.height = newHeight;
    self.frame = newFrame;
    
    scrollView.contentSize = newFrame.size;
}

- (void)setSelectedImage:(NSUInteger)index {
    if (index >= NUM_IMAGES) {
        return;
    }
    selectedImageIndex = index;
    
    NSUInteger row = index / imagesPerRow;
    NSUInteger col = index - (row * imagesPerRow);
    
    CGSize size = selectedImageView.image.size;
    CGRect frame = CGRectMake((col + 1) * (SIZE + 2 * HORIZONTAL_SPACING) - size.width, (row + 1) * (SIZE + 2 * VERTICAL_SPACING) - size.height, size.width, size.height);
    selectedImageView.frame = frame;
}

@end
