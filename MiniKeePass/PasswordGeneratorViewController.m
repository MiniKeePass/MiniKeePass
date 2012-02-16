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

#import "PasswordGeneratorViewController.h"
#import "LengthViewController.h"
#import "Salsa20RandomStream.h"

#define CHARSET_LOWER_CASE @"abcdefghijklmnopqrstuvwxyz"
#define CHARSET_UPPER_CASE @"ABCDEFGHIJKLMNOPQRSTUVWXYZ"
#define CHARSET_DIGITS     @"0123456789"
#define CHARSET_MINUS      @"-"
#define CHARSET_UNDERLINE  @"_"
#define CHARSET_SPACE      @" "
#define CHARSET_SPECIAL    @"!@#$%^&*_-+=?"
#define CHARSET_BRACKETS   @"(){}[]<>"

enum {
    SECTION_SETTINGS,
    SECTION_PASSWORD,
    SECTION_NUMBER
};

enum {
    ROW_SETTINGS_LENGTH,
    ROW_SETTINGS_CHARSET,
    ROW_SETTINGS_NUMBER
};

enum {
    ROW_PASSWORD_VALUE,
    ROW_PASSWORD_NUMBER
};

@implementation PasswordGeneratorViewController

@synthesize delegate;

- (id)init {
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        self.title = @"Generator";
        self.tableView.delaysContentTouches = YES;
        
        UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Cancel", nil) style:UIBarButtonItemStylePlain target:self action:@selector(cancelPressed)];
        self.navigationItem.rightBarButtonItem = cancelButton;
        [cancelButton release];

        lengthCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:nil];
        lengthCell.textLabel.text = @"Length";
        lengthCell.detailTextLabel.text = @" ";
        lengthCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        
        characterSetsCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:nil];
        characterSetsCell.textLabel.text = @"Character Sets";
        characterSetsCell.detailTextLabel.text = @" ";
        characterSetsCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        
        UIImage *image = [UIImage imageNamed:@"gear"];
        
        UIButton *regenerateButton = [UIButton buttonWithType:UIButtonTypeCustom];
        regenerateButton.frame = CGRectMake(0.0, 0.0, image.size.width, image.size.height);
        [regenerateButton setImage:image forState:UIControlStateNormal];
        [regenerateButton addTarget:self action:@selector(generatePassword) forControlEvents:UIControlEventTouchUpInside];
        
        passwordCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
        passwordCell.textLabel.text = @" "; // FIXME Why do I have to pass a space in?
        passwordCell.textLabel.font = [UIFont fontWithName:@"Monaco" size:16];
        passwordCell.accessoryView = regenerateButton;
    }
    return self;
}

- (void)dealloc {
    [lengthCell release];
    [characterSetsCell release];
    [passwordCell release];
    [super dealloc];
}

- (void)viewWillAppear:(BOOL)animated {
    // Mark the view as not being canceled
    canceled = NO;
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    length = [userDefaults integerForKey:@"pwGenLength"];
    charSets = [userDefaults integerForKey:@"pwGenCharSets"];
    
    lengthCell.detailTextLabel.text = [[NSNumber numberWithInteger:length] stringValue];
    characterSetsCell.detailTextLabel.text = [self createCharSetsDescription];
    
    [self generatePassword];
}

- (void)viewWillDisappear:(BOOL)animated {
    if (!canceled) {
        if ([delegate respondsToSelector:@selector(passwordGeneratorViewController:password:)]) {
            [delegate passwordGeneratorViewController:self password:passwordCell.textLabel.text];
        }
    }
}

- (void)cancelPressed {
    canceled = YES;
    [self.navigationController popViewControllerAnimated:YES];
}

- (NSString *)getPassword {
    return passwordCell.textLabel.text;
}

- (void)generatePassword {
    NSMutableString *charSet = [NSMutableString string];
    
    if (charSets & CHARACTER_SET_UPPER_CASE) {
        [charSet appendString:CHARSET_UPPER_CASE];
    }
    if (charSets & CHARACTER_SET_LOWER_CASE) {
        [charSet appendString:CHARSET_LOWER_CASE];
    }
    if (charSets & CHARACTER_SET_DIGITS) {
        [charSet appendString:CHARSET_DIGITS];
    }
    if (charSets & CHARACTER_SET_MINUS) {
        [charSet appendString:CHARSET_MINUS];
    }
    if (charSets & CHARACTER_SET_UNDERLINE) {
        [charSet appendString:CHARSET_UNDERLINE];
    }
    if (charSets & CHARACTER_SET_SPACE) {
        [charSet appendString:CHARSET_SPACE];
    }
    if (charSets & CHARACTER_SET_SPECIAL) {
        [charSet appendString:CHARSET_SPECIAL];
    }
    
    RandomStream *cryptoRandomStream = [[Salsa20RandomStream alloc] init];
    
    NSMutableString *password = [NSMutableString string];
    for (NSUInteger i = 0; i < length; i++) {
        NSUInteger idx = [cryptoRandomStream getInt] % [charSet length];
	        [password appendString:[charSet substringWithRange:NSMakeRange(idx, 1)]];
    }
    
    [cryptoRandomStream release];
    
    passwordCell.textLabel.text = password;
}

- (NSString *)createCharSetsDescription {
    NSMutableString *str = [[NSMutableString alloc] init];
    BOOL prefix = NO;
    
    if (charSets & CHARACTER_SET_UPPER_CASE) {
        if (prefix) {
            [str appendString:@", "];
        }
        [str appendString:@"Upper"];
        prefix = YES;
    }
    
    if (charSets & CHARACTER_SET_LOWER_CASE) {
        if (prefix) {
            [str appendString:@", "];
        }
        [str appendString:@"Lower"];
        prefix = YES;
    }
    
    if (charSets & CHARACTER_SET_DIGITS) {
        if (prefix) {
            [str appendString:@", "];
        }
        [str appendString:@"Digits"];
        prefix = YES;
    }
    
    if (charSets & CHARACTER_SET_MINUS) {
        if (prefix) {
            [str appendString:@", "];
        }
        [str appendString:@"Minus"];
        prefix = YES;
    }
    
    if (charSets & CHARACTER_SET_UNDERLINE) {
        if (prefix) {
            [str appendString:@", "];
        }
        [str appendString:@"Underline"];
        prefix = YES;
    }
    
    if (charSets & CHARACTER_SET_SPACE) {
        if (prefix) {
            [str appendString:@", "];
        }
        [str appendString:@"Space"];
        prefix = YES;
    }
    
    if (charSets & CHARACTER_SET_SPECIAL) {
        if (prefix) {
            [str appendString:@", "];
        }
        [str appendString:@"Special"];
        prefix = YES;
    }
    
    if (charSets & CHARACTER_SET_BRACKETS) {
        if (prefix) {
            [str appendString:@", "];
        }
        [str appendString:@"Brackets"];
        prefix = YES;
    }
    
    if ([str length] == 0) {
        [str appendString:@"None Selected"];
    }
    
    return [str autorelease];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return SECTION_NUMBER;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case SECTION_SETTINGS:
            return ROW_SETTINGS_NUMBER;
            
        case SECTION_PASSWORD:
            return ROW_PASSWORD_NUMBER;
    }
    return 0;
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case SECTION_SETTINGS:
            return NSLocalizedString(@"Settings", nil);
            
        case SECTION_PASSWORD:
            return NSLocalizedString(@"Password", nil);
    }
    return nil;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case SECTION_SETTINGS:
            switch (indexPath.row) {
                case ROW_SETTINGS_LENGTH:
                    return lengthCell;
                case ROW_SETTINGS_CHARSET:
                    return characterSetsCell;
            }
            break;
            
        case SECTION_PASSWORD:
            switch (indexPath.row) {
                case ROW_PASSWORD_VALUE:
                    return passwordCell;
            }
            break;
    }
    
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == SECTION_SETTINGS && indexPath.row == ROW_SETTINGS_LENGTH) {
        LengthViewController *lengthViewController = [[LengthViewController alloc] initWithMinValue:1 maxValue:25];
        [self.navigationController pushViewController:lengthViewController animated:YES];
        [lengthViewController release];
    } else if (indexPath.section == SECTION_SETTINGS && indexPath.row == ROW_SETTINGS_CHARSET) {
        CharacterSetsViewController *characterSetViewController = [[CharacterSetsViewController alloc] init];
        [self.navigationController pushViewController:characterSetViewController animated:YES];
        [characterSetViewController release];
    }
}

@end
