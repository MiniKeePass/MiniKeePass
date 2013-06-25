/*
 * Copyright 2011-2012 Jason Rush and John Flanagan. All rights reserved.
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

#import "LengthCell.h"

@implementation LengthCell

@synthesize delegate;
@synthesize inputView;
@synthesize inputAccessoryView;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.textLabel.text = NSLocalizedString(@"Length", nil);
        self.detailTextLabel.text = @" ";
        
        pickerView = [[UIPickerView alloc] init];
        pickerView.showsSelectionIndicator = YES;
        pickerView.delegate = self;
        pickerView.dataSource = self;
        self.inputView = pickerView;
        
        UIToolbar *toolbar = [[UIToolbar alloc] init];
        toolbar.barStyle = UIBarStyleBlackTranslucent;
        [toolbar sizeToFit];

        UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(resignFirstResponder)];

        toolbar.items = [NSArray arrayWithObjects:flexibleSpace, doneButton, nil];
        
        self.inputAccessoryView = toolbar;
    }
    return self;
}

- (void)setLength:(NSInteger)length {
    self.detailTextLabel.text = [[NSNumber numberWithInteger:length] stringValue];
    
    [pickerView selectRow:length-1 inComponent:0 animated:YES];
}

- (void)setLngth:(NSInteger)length {
    
}

- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    [self becomeFirstResponder];
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return 25;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    return [[NSNumber numberWithInteger:row + 1] stringValue];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    NSInteger length = row + 1;
    
    self.detailTextLabel.text = [[NSNumber numberWithInteger:length] stringValue];

    if ([delegate respondsToSelector:@selector(lengthCell:length:)]) {
        [delegate lengthCell:self length:length];
    }
}

@end
