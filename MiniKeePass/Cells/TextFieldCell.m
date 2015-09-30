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

#import "TextFieldCell.h"
#import <UIKit/UIPasteboard.h>
#import "VersionUtils.h"

@interface TextFieldCell()
@property (nonatomic, strong) UIView *grayBar;
@end

@implementation TextFieldCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        int inset;
        if (SYSTEM_VERSION_LESS_THAN(@"7.0")) {
            inset = 83;
        } else {
            inset = 115;
        }

        CGRect frame = self.contentView.frame;
        frame.origin.x = inset;
        frame.size.width -= inset;
        
        _textField = [[UITextField alloc] initWithFrame:frame];
        _textField.delegate = self;
        _textField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        _textField.textColor = [UIColor colorWithRed:.285 green:.376 blue:.541 alpha:1];
        _textField.font = [UIFont systemFontOfSize:16];
        _textField.returnKeyType = UIReturnKeyNext;
        _textField.clearButtonMode = UITextFieldViewModeWhileEditing;
        _textField.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        _textField.font = [UIFont boldSystemFontOfSize:15];
        _textField.textColor = [UIColor blackColor];
        
        [self.contentView addSubview:self.textField];

        CGFloat grayIntensity = 202.0 / 255.0;
        UIColor *color = [UIColor colorWithRed:grayIntensity green:grayIntensity blue:grayIntensity alpha:1];

        _grayBar = [[UIView alloc] initWithFrame:CGRectMake(inset - 4, -1, 1, self.contentView.frame.size.height - 4)];
        _grayBar.backgroundColor = color;
        _grayBar.hidden = YES;
        [self.contentView addSubview:_grayBar];
    }
    return self;
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *hitView = [super hitTest:point withEvent:event];
    if (hitView == nil) {
        return nil;
    }

    if (!self.selected) {
        UIView *newView = self.editing ? _editAccessoryButton : _accessoryButton;
        if (newView == nil) {
            return hitView;
        }

        CGPoint newPoint = [self convertPoint:point toView:newView];

        // Pass along touch events that occur to the right of the accessory view to the accessory view
        if (newPoint.x >= 0.0f) {
            hitView = newView;
        }
    }

    return hitView;
}

- (BOOL)showGrayBar {
    return !self.grayBar.hidden;
}

- (void)setShowGrayBar:(BOOL)showGrayBar {
    self.grayBar.hidden = !showGrayBar;
}

- (void)setAccessoryButton:(UIButton *)accessoryButton {
    _accessoryButton = accessoryButton;
    self.accessoryView = accessoryButton;
}

- (void)setEditAccessoryButton:(UIButton *)editAccessoryButton {
    _editAccessoryButton = editAccessoryButton;
    self.editingAccessoryView = editAccessoryButton;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    // No-op
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    if ([self.textFieldCellDelegate respondsToSelector:@selector(textFieldCellDidEndEditing:)]) {
        [self.textFieldCellDelegate textFieldCellDidEndEditing:self];
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)field {
    if ([self.textFieldCellDelegate respondsToSelector:@selector(textFieldCellWillReturn:)]) {
        [self.textFieldCellDelegate textFieldCellWillReturn:self];
    }
    
    return NO;
}

@end
