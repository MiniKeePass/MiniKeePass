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

#import "EditGroupViewController.h"
#import "MiniKeePassAppDelegate.h"

@interface EditGroupViewController () {
    ImageButtonCell *imageButtonCell;
}
@end

@implementation EditGroupViewController

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        self.title = NSLocalizedString(@"Edit Group", nil);
        
        _nameTextField = [[UITextField alloc] init];
        _nameTextField.placeholder = NSLocalizedString(@"Name", nil);
        _nameTextField.delegate = self;
        _nameTextField.returnKeyType = UIReturnKeyDone;
        _nameTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
        
        imageButtonCell = [[ImageButtonCell alloc] initWithLabel:NSLocalizedString(@"Image", nil)];
        [imageButtonCell.imageButton addTarget:self
                                        action:@selector(imageButtonPressed)
                              forControlEvents:UIControlEventTouchUpInside];
        
        self.controls = [NSArray arrayWithObjects:_nameTextField, imageButtonCell, nil];
    }
    return self;
}

- (void)dealloc {
    [_nameTextField release];
    [super dealloc];
}

- (void)setSelectedImageIndex:(NSUInteger)selectedImageIndex {
    _selectedImageIndex = selectedImageIndex;
    
    MiniKeePassAppDelegate *appDelegate = (MiniKeePassAppDelegate *)[[UIApplication sharedApplication] delegate];
    [imageButtonCell.imageButton setImage:[appDelegate loadImage:_selectedImageIndex] forState:UIControlStateNormal];
}

- (void)imageButtonPressed {
    ImageSelectionViewController *imageSelectionViewController = [[ImageSelectionViewController alloc] init];
    imageSelectionViewController.imageSelectionView.delegate = self;
    imageSelectionViewController.imageSelectionView.selectedImageIndex = _selectedImageIndex;
    [self.navigationController pushViewController:imageSelectionViewController animated:YES];
    [imageSelectionViewController release];
}

- (void)imageSelectionView:(ImageSelectionView *)imageSelectionView selectedImageIndex:(NSUInteger)imageIndex {
    self.selectedImageIndex = imageIndex;
}

@end
