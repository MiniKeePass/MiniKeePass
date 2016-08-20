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

#import "EditItemViewController.h"
#import "ImageButtonCell.h"
#import "ImageFactory.h"
#import "MiniKeePass-Swift.h"

@interface EditItemViewController ()
@property (nonatomic, strong) ImageButtonCell *imageButtonCell;
@end

@implementation EditItemViewController

- (id)init {
    self = [super init];
    if (self) {
        _nameTextField = [[UITextField alloc] init];
        self.nameTextField.placeholder = NSLocalizedString(@"Name", nil);
        self.nameTextField.delegate = self;
        self.nameTextField.returnKeyType = UIReturnKeyDone;
        self.nameTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
        
        self.imageButtonCell = [[ImageButtonCell alloc] initWithLabel:NSLocalizedString(@"Image", nil)];
        [self.imageButtonCell.imageButton addTarget:self
                                        action:@selector(imageButtonPressed)
                              forControlEvents:UIControlEventTouchUpInside];
        
        self.controls = [NSArray arrayWithObjects:self.nameTextField, self.imageButtonCell, nil];
    }
    return self;
}

- (id)initWithEntry:(KdbEntry *)entry {
    self = [self init];
    if (self) {
        self.title = NSLocalizedString(@"Edit Entry", nil);

        self.nameTextField.text = entry.title;
        [self setSelectedImageIndex:entry.image];
    }
    return self;
}

- (id)initWithGroup:(KdbGroup *)group {
    self = [self init];
    if (self) {
        self.title = NSLocalizedString(@"Edit Group", nil);

        self.nameTextField.text = group.name;
        [self setSelectedImageIndex:group.image];
    }
    return self;
}

- (void)setSelectedImageIndex:(NSUInteger)selectedImageIndex {
    _selectedImageIndex = selectedImageIndex;
    
    UIImage *image = [[ImageFactory sharedInstance] imageForIndex:selectedImageIndex];
    [self.imageButtonCell.imageButton setImage:image forState:UIControlStateNormal];
}

- (void)imageButtonPressed {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"ImageSelector" bundle:nil];
    ImageSelectorViewController *imageSelectorViewController = [storyboard instantiateInitialViewController];
    imageSelectorViewController.selectedImage = _selectedImageIndex;
    imageSelectorViewController.imageSelected = ^(ImageSelectorViewController *imageSelectorViewController, NSInteger selectedImage) {
        self.selectedImageIndex = selectedImage;
    };
    
    [self.navigationController pushViewController:imageSelectorViewController animated:YES];
}

@end
