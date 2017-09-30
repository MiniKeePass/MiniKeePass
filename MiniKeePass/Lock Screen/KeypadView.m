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

#import "KeypadView.h"
#import "KeypadButton.h"

@interface KeypadView ()
@property (nonatomic, strong) NSArray *buttons;
@end

@implementation KeypadView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        KeypadButton *alphaButton = [KeypadButton systemButtonWithTitle:@"A-Z"];
        KeypadButton *deleteButton = [KeypadButton systemButtonWithTitle:@"Delete"];

        self.buttons = @[
                         [KeypadButton numberButtonWithValue:1 andSubtitle:@""],
                         [KeypadButton numberButtonWithValue:2 andSubtitle:@"ABC"],
                         [KeypadButton numberButtonWithValue:3 andSubtitle:@"DEF"],
                         [KeypadButton numberButtonWithValue:4 andSubtitle:@"GHI"],
                         [KeypadButton numberButtonWithValue:5 andSubtitle:@"JKL"],
                         [KeypadButton numberButtonWithValue:6 andSubtitle:@"MNO"],
                         [KeypadButton numberButtonWithValue:7 andSubtitle:@"PQRS"],
                         [KeypadButton numberButtonWithValue:8 andSubtitle:@"TUV"],
                         [KeypadButton numberButtonWithValue:9 andSubtitle:@"WXYZ"],
                         alphaButton,
                         [KeypadButton numberButtonWithValue:0 andSubtitle:nil],
                         deleteButton,
                         ];

        for (KeypadButton *button in self.buttons) {
            if ((NSObject *)button == [NSNull null]) {
                continue;
            }

            if (button == alphaButton) {
                [button addTarget:self action:@selector(alphaPressed:) forControlEvents:UIControlEventTouchDown];
            } else if (button == deleteButton) {
                [button addTarget:self action:@selector(deletePressed:) forControlEvents:UIControlEventTouchDown];
            } else {
                [button addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchDown];
            }

            [self addSubview:button];
        }
        
        [self sizeToFit];
    }
    return self;
}

- (CGSize)sizeThatFits:(CGSize)size {
    NSInteger cols = 3;
    NSInteger rows = self.buttons.count / 3.0f + 0.5f;

    CGFloat width = (KEYPAD_BUTTON_SIZE * cols) + (KEYPAD_BUTTON_XPADDING * (cols - 1));
    CGFloat height = (KEYPAD_BUTTON_SIZE * rows) + (KEYPAD_BUTTON_YPADDING * (rows - 1));

    return CGSizeMake(width, height);
}

- (void)layoutSubviews {
    [super layoutSubviews];

    [self.buttons enumerateObjectsUsingBlock:^(KeypadButton *button, NSUInteger idx, BOOL *stop) {
        if ((NSObject *)button == [NSNull null]) {
            return;
        }

        NSInteger row = idx / 3;
        NSInteger col = idx % 3;

        CGFloat x = col * (KEYPAD_BUTTON_SIZE + KEYPAD_BUTTON_XPADDING);
        CGFloat y = row * (KEYPAD_BUTTON_SIZE + KEYPAD_BUTTON_YPADDING);

        button.frame = CGRectMake(x, y, KEYPAD_BUTTON_SIZE, KEYPAD_BUTTON_SIZE);
    }];
}

#pragma mark - Button handlers

- (void)buttonPressed:(KeypadButton *)source {
    [self.delegate keypadView:self numberPressed:source.mainLabel.text];
}

- (void)deletePressed:(KeypadButton *)source {
    [self.delegate keypadViewDeletePressed:self];
}

- (void)alphaPressed:(KeypadButton *)source {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.3f * NSEC_PER_SEC), dispatch_get_main_queue(), ^(void) {
        [source clearHighlight];
    });
    
    [self.delegate keypadViewAlphaPressed:self];
}

@end
