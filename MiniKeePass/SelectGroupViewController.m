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

#import "SelectGroupViewController.h"
#import "MiniKeePassAppDelegate.h"
#import "ImageFactory.h"

#define DEFAULT_SPACER_WIDTH 10.0f

static NSString *const kKeySelectable = @"selectable";
static NSString *const kKeyGroup = @"group";
static NSString *const kKeyLevel = @"level";
static NSString *const kKeyName = @"name";

@interface IndentTableViewCell : UITableViewCell
@property (nonatomic, assign) NSUInteger level;
@property (nonatomic, assign) NSUInteger spacerWidth;
@end

@implementation IndentTableViewCell

- (void)layoutSubviews {
    [super layoutSubviews];

    CGFloat imageWidth = self.imageView.bounds.size.width;

    if ([self respondsToSelector:@selector(setSeparatorInset:)]) {
        self.imageView.frame = CGRectMake(self.spacerWidth + (imageWidth + self.spacerWidth) * self.level,
                                          self.imageView.frame.origin.y,
                                          self.imageView.frame.size.width,
                                          self.imageView.frame.size.height);

        self.separatorInset = UIEdgeInsetsMake(0,
                                               self.spacerWidth + (imageWidth + self.spacerWidth) * (self.level + 1),
                                               0,
                                               0);
    } else {
        CGFloat indentation = (imageWidth + self.spacerWidth) * self.level;
        self.contentView.frame = CGRectMake(indentation,
                                            self.contentView.frame.origin.y,
                                            self.contentView.frame.size.width - indentation,
                                            self.contentView.frame.size.height);
        self.textLabel.frame = CGRectMake(self.textLabel.frame.origin.x,
                                          self.textLabel.frame.origin.y,
                                          self.textLabel.frame.size.width - indentation,
                                          self.textLabel.frame.size.height);
    }
}

@end

@interface SelectGroupViewController ()

@property (nonatomic, strong) NSMutableArray *allGroups;
@property (nonatomic, weak) MiniKeePassAppDelegate *appDelegate;

@end

@implementation SelectGroupViewController

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) {
        self.title = NSLocalizedString(@"Choose Group", nil);

        self.allGroups = [[NSMutableArray alloc] init];
        self.appDelegate = [MiniKeePassAppDelegate appDelegate];

        UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(dismissModalViewControllerAnimated:)];
        self.navigationItem.leftBarButtonItem = cancelButton;
    }
    return self;
}

- (void)viewDidLoad {
    // Get parameters for the root
    KdbGroup *rootGroup = self.appDelegate.databaseDocument.kdbTree.root;
    NSString *filename = [self.appDelegate.databaseDocument.filename lastPathComponent];

    // Recursivly add subgroups
    [self addGroup:rootGroup withName:filename atLevel:0];
}

- (void)addGroup:(KdbGroup *)group withName:(NSString *)name atLevel:(NSInteger)level {
    BOOL selectable = [self.delegate selectGroupViewController:self canSelectGroup:group];
    [self.allGroups addObject:@{kKeyGroup : group,
                                kKeyLevel : [NSNumber numberWithInteger:level],
                                kKeyName : name,
                                kKeySelectable : [NSNumber numberWithBool:selectable]}];

    // Sort all the sub-groups
    NSArray *sortedGroups = [group.groups sortedArrayUsingComparator:^NSComparisonResult(KdbGroup *group1, KdbGroup *group2) {
        return [group1.name localizedCaseInsensitiveCompare:group2.name];
    }];

    // Add sub-groups
    for (KdbGroup *group in sortedGroups) {
        [self addGroup:group withName:group.name atLevel:level + 1];
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.allGroups count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";

    IndentTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[IndentTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }

    NSDictionary *dict = [self.allGroups objectAtIndex:indexPath.row];
    KdbGroup *group = [dict objectForKey:kKeyGroup];

    cell.textLabel.text = [dict objectForKey:kKeyName];
    cell.imageView.image = [[ImageFactory sharedInstance] imageForGroup:group];
    cell.level = [[dict objectForKey:kKeyLevel] integerValue];

    if ([tableView respondsToSelector:@selector(setSeparatorInset:)]) {
        cell.spacerWidth = tableView.separatorInset.left;
    } else {
        cell.spacerWidth = DEFAULT_SPACER_WIDTH;
    }

    BOOL selectable = [[dict objectForKey:kKeySelectable] boolValue];
    if (selectable) {
        cell.textLabel.textColor = [UIColor blackColor];
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    } else {
        cell.textLabel.textColor = [UIColor lightGrayColor];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }

    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *groupDict = [self.allGroups objectAtIndex:indexPath.row];

    BOOL selectable = [[groupDict objectForKey:kKeySelectable] boolValue];
    if (selectable) {
        KdbGroup *selectedGroup = [groupDict objectForKey:kKeyGroup];
        [self.delegate selectGroupViewController:self selectedGroup:selectedGroup];
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

@end
