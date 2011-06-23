//
//  EditGroupViewController.m
//  MiniKeePass
//
//  Created by Jason Rush on 6/23/11.
//  Copyright 2011 Self. All rights reserved.
//

#import "EditGroupViewController.h"
#import "MiniKeePassAppDelegate.h"

@implementation EditGroupViewController

@synthesize nameTextField;
@synthesize imageButton;

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        self.title = @"Edit Group";
        
        nameTextField = [[UITextField alloc] init];
        nameTextField.placeholder = @"Name";
        nameTextField.returnKeyType = UIReturnKeyDone;
        nameTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
        
        imageButton = [[UIButton alloc] init];
        [imageButton addTarget:self action:@selector(imageButtonPressed) forControlEvents:UIControlEventTouchUpInside];
        
        self.controls = [NSArray arrayWithObjects:nameTextField, imageButton, nil];
    }
    return self;
}

- (void)dealloc {
    [nameTextField release];
    [super dealloc];
}

- (NSUInteger)selectedImageIndex {
    return selectedImageIndex;
}

- (void)setSelectedImageIndex:(NSUInteger)index {
    selectedImageIndex = index;
    
    MiniKeePassAppDelegate *appDelegate = (MiniKeePassAppDelegate*)[[UIApplication sharedApplication] delegate];
    [imageButton setImage:[appDelegate loadImage:index] forState:UIControlStateNormal];
}

- (void)imageButtonPressed {
    ImagesViewController *imagesViewController = [[ImagesViewController alloc] init];
    imagesViewController.delegate = self;
    [imagesViewController setSelectedImage:selectedImageIndex];
    [self.navigationController pushViewController:imagesViewController animated:YES];
    [imagesViewController release];
}

- (void)imagesViewController:(ImagesViewController *)controller imageSelected:(NSUInteger)index {
    [self setSelectedImageIndex:index];
}

@end
