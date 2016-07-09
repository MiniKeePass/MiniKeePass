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

#import <UIKit/UIKit.h>

#define KEYPAD_BUTTON_SIZE     75
#define KEYPAD_BUTTON_XPADDING 20
#define KEYPAD_BUTTON_YPADDING 12

@interface KeypadButton : UIButton

@property (nonatomic, strong) UILabel *mainLabel;
@property (nonatomic, strong) UILabel *subtitleLabel;

- (instancetype)initWithTitle:(NSString *)title andSubtitle:(NSString *)subtitle;

+ (KeypadButton *)numberButtonWithValue:(NSInteger)value andSubtitle:(NSString *)subtitle;
+ (KeypadButton *)systemButtonWithTitle:(NSString *)title;

- (void)clearHighlight;

@end
