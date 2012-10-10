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

#import "RenameItemViewController.h"
#import "MiniKeePassAppDelegate.h"

@implementation RenameItemViewController

@synthesize nameTextField;

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        nameTextField = [[UITextField alloc] init];
        nameTextField.placeholder = NSLocalizedString(@"Name", nil);
        nameTextField.delegate = self;
        nameTextField.returnKeyType = UIReturnKeyDone;
        nameTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
        
        imageButtonCell = [[ImageButtonCell alloc] initWithLabel:NSLocalizedString(@"Image", nil)];
        [imageButtonCell.imageButton addTarget:self action:@selector(imageButtonPressed) forControlEvents:UIControlEventTouchUpInside];
        
        self.controls = [NSArray arrayWithObjects:nameTextField, imageButtonCell, nil];
    }
    return self;
}

- (void)dealloc {
    [nameTextField release];
    [super dealloc];
}

- (void)setType:(RenameItemType)type {
    _type = type;
    switch (_type) {
        case RenameItemTypeGroup:
            self.title = [NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"Rename", nil), NSLocalizedString(@"Group", nil)];
            break;

        case RenameItemTypeEntry:
            self.title = [NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"Rename", nil), NSLocalizedString(@"Entry", nil)];
            break;
    }
}

- (NSUInteger)selectedImageIndex {
    return selectedImageIndex;
}

- (void)setSelectedImageIndex:(NSUInteger)index {
    selectedImageIndex = index;
    
    MiniKeePassAppDelegate *appDelegate = (MiniKeePassAppDelegate*)[[UIApplication sharedApplication] delegate];
    [imageButtonCell.imageButton setImage:[appDelegate loadImage:index] forState:UIControlStateNormal];
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
