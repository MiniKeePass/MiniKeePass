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

#import <UIKit/UIKit.h>
#import "SwitchCell.h"

#define CHARACTER_SET_UPPER_CASE (1 << 0)
#define CHARACTER_SET_LOWER_CASE (1 << 1)
#define CHARACTER_SET_DIGITS     (1 << 2)
#define CHARACTER_SET_MINUS      (1 << 3)
#define CHARACTER_SET_UNDERLINE  (1 << 4)
#define CHARACTER_SET_SPACE      (1 << 5)
#define CHARACTER_SET_SPECIAL    (1 << 6)
#define CHARACTER_SET_BRACKETS   (1 << 7)

#define CHARACTER_SET_DEFAULT    (CHARACTER_SET_UPPER_CASE | CHARACTER_SET_LOWER_CASE | CHARACTER_SET_DIGITS)

@interface CharacterSetsViewController : UITableViewController {
    SwitchCell *upperCaseSwitchCell;
    SwitchCell *lowerCaseSwitchCell;
    SwitchCell *digitsSwitchCell;
    SwitchCell *minusSwitchCell;
    SwitchCell *underlineSwitchCell;
    SwitchCell *spaceSwitchCell;
    SwitchCell *specialSwitchCell;
    SwitchCell *bracketsSwitchCell;
}

- (id)init;

@end
