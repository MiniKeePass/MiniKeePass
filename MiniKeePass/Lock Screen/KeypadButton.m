/*
 * Copyright 2011-2014 Jason Rush and John Flanagan. All rights reserved.
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

#import "KeypadButton.h"
#import <QuartzCore/QuartzCore.h>

@interface KeypadButton ()
@property (nonatomic, assign) BOOL borderHidden;
@property (nonatomic, strong) UIColor *textColor;
@property (nonatomic, strong) UIColor *highlightTextColor;
@property (nonatomic, strong) UIColor *borderColor;
@property (nonatomic, strong) UIColor *highlightBackgroundColor;
@end

@implementation KeypadButton

- (instancetype)initWithTitle:(NSString *)title andSubtitle:(NSString *)subtitle {
    self = [super initWithFrame:CGRectMake(0, 0, KEYPAD_BUTTON_SIZE, KEYPAD_BUTTON_SIZE)];
    if (self) {
        _mainLabel = [[UILabel alloc] init];
        _mainLabel.text = title;
        _mainLabel.textAlignment = NSTextAlignmentCenter;
        [self addSubview:_mainLabel];

        if (subtitle != nil) {
            _subtitleLabel = [[UILabel alloc] init];
            _subtitleLabel.text = subtitle;
            _subtitleLabel.textAlignment = NSTextAlignmentCenter;
            [self addSubview:_subtitleLabel];
        }
    }
    return self;
}

+ (KeypadButton *)numberButtonWithValue:(NSInteger)value andSubtitle:(NSString *)subtitle {
    NSString *title = [NSString stringWithFormat:@"%ld", (long)value];

    KeypadButton *keypadButton = [[KeypadButton alloc] initWithTitle:title andSubtitle:subtitle];
    keypadButton.tag = value;

    keypadButton.mainLabel.font = [keypadButton.mainLabel.font fontWithSize:28];
    if (subtitle != nil) {
        keypadButton.subtitleLabel.font = [keypadButton.subtitleLabel.font fontWithSize:12];
    }

    keypadButton.borderHidden = NO;
    keypadButton.textColor = [UIColor darkGrayColor];
    keypadButton.highlightTextColor = [UIColor whiteColor];
    keypadButton.borderColor = [UIColor darkGrayColor];
    keypadButton.highlightBackgroundColor = [UIColor colorWithRed:0x33/255.0f green:0xAA/255.0f blue:0xDC/255.0f alpha:1.0f];

    return keypadButton;
}

+ (KeypadButton *)systemButtonWithTitle:(NSString *)title {
    KeypadButton *keypadButton = [[KeypadButton alloc] initWithTitle:title andSubtitle:nil];

    keypadButton.mainLabel.font = [keypadButton.mainLabel.font fontWithSize:22];
    keypadButton.borderHidden = YES;
    keypadButton.textColor = [UIColor darkGrayColor];
    keypadButton.highlightTextColor = [UIColor colorWithRed:0x33/255.0f green:0xAA/255.0f blue:0xDC/255.0f alpha:1.0f];
    keypadButton.highlightBackgroundColor = [UIColor clearColor];

    return keypadButton;
}

- (void)layoutSubviews {
    [super layoutSubviews];

    CGFloat w = self.bounds.size.width;
    CGFloat h = self.bounds.size.width;

    [_mainLabel sizeToFit];

    if (_subtitleLabel == nil) {
        _mainLabel.frame = CGRectMake(0, h / 2.0f - _mainLabel.bounds.size.height / 2.0f, w, _mainLabel.bounds.size.height);
    } else {
        _mainLabel.frame = CGRectMake(0, h / 6.0f, w, _mainLabel.bounds.size.height);

        [_subtitleLabel sizeToFit];
        _subtitleLabel.frame = CGRectMake(0, _mainLabel.frame.origin.y + _mainLabel.frame.size.height + 3, w, _subtitleLabel.bounds.size.height);
    }
}

#pragma mark - Instance variable setters

- (void)setBorderHidden:(BOOL)borderHidden {
    _borderHidden = borderHidden;

    if (!borderHidden) {
        self.layer.borderWidth = 1.5f;
        self.layer.cornerRadius = self.bounds.size.width / 2.0f;
    }
}

- (void)setTextColor:(UIColor *)textColor {
    _textColor = textColor;

    _mainLabel.textColor = textColor;
    if (_subtitleLabel != nil) {
        _subtitleLabel.textColor = textColor;
    }
}

- (void)setBorderColor:(UIColor *)borderColor {
    _borderColor = borderColor;

    self.layer.borderColor = [self.mainLabel.textColor CGColor];
}

#pragma mark - Touch event handlers

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];

    self.backgroundColor = _highlightBackgroundColor;

    if (!_borderHidden) {
        self.layer.borderColor = [_highlightBackgroundColor CGColor];
    }

    _mainLabel.textColor = _highlightTextColor;

    if (_subtitleLabel != nil) {
        _subtitleLabel.textColor = _highlightTextColor;
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesEnded:touches withEvent:event];

    [UIView animateWithDuration:0.3f
                          delay:0.0f
                        options:UIViewAnimationOptionAllowUserInteraction
                     animations:^{
                         [self clearHighlight];
                     }
                     completion:nil];
}

- (void)clearHighlight {
    self.backgroundColor = [UIColor clearColor];
    
    if (!_borderHidden) {
        self.layer.borderColor = [_borderColor CGColor];
    }
    
    _mainLabel.textColor = _textColor;
    
    if (_subtitleLabel != nil) {
        _subtitleLabel.textColor = _textColor;
    }
}

@end
