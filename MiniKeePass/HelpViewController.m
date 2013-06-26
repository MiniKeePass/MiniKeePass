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

#import "HelpViewController.h"
#import "AutorotatingViewController.h"

@interface HelpTopic : NSObject
- (HelpTopic *)initWithTitle:(NSString *)title andResource:(NSString *)resource;
+ (HelpTopic *)helpTopicWithTitle:(NSString *)title andResource:(NSString *)resource;
@property (nonatomic, copy) NSString* title;
@property (nonatomic, copy) NSString* resource;
@end

@implementation HelpTopic

- (HelpTopic *)initWithTitle:(NSString *)title andResource:(NSString *)resource {
    self = [super init];
    if (self) {
        _title = [title copy];
        _resource = [resource copy];
    }
    return self;
}

+ (HelpTopic *)helpTopicWithTitle:(NSString *)title andResource:(NSString *)resource {
    return [[[HelpTopic alloc] initWithTitle:title andResource:resource] autorelease];
}

- (void)dealloc {
    [_title release];
    [_resource release];
    [super dealloc];
}

@end

@interface HelpViewController ()
@property (nonatomic, retain) NSArray *helpTopics;
@end

@implementation HelpViewController

- (id)init {
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        self.title = NSLocalizedString(@"Help", nil);
        _helpTopics = [@[
                         [HelpTopic helpTopicWithTitle:@"iTunes Import/Export" andResource:@"itunes"],
                         [HelpTopic helpTopicWithTitle:@"Dropbox Import/Export" andResource:@"dropbox"],
                         [HelpTopic helpTopicWithTitle:@"Safari/Email Import" andResource:@"safariemail"],
                         [HelpTopic helpTopicWithTitle:@"Create New Database" andResource:@"createdb"],
                         [HelpTopic helpTopicWithTitle:@"Key Files" andResource:@"keyfiles"]
                        ] retain];
    }
    return self;
}

- (void)dealloc {
    [_helpTopics release];
    [super dealloc];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _helpTopics.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    // Configure the cell
    cell.textLabel.text = NSLocalizedString(((HelpTopic *)_helpTopics[indexPath.row]).title, nil);
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Get the title and resource of the selected help page
    NSString *title = ((HelpTopic *)_helpTopics[indexPath.row]).title;
    NSString *resource = ((HelpTopic *)_helpTopics[indexPath.row]).resource;
    
    NSString *language = [[NSLocale preferredLanguages] objectAtIndex:0];
    NSString *localizedResource = [NSString stringWithFormat:@"%@-%@", language, resource];

    NSString *path = [[NSBundle mainBundle] pathForResource:localizedResource ofType:@"html"];
    if(![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        path = [[NSBundle mainBundle] pathForResource:resource ofType:@"html"];
    }
    
    // Get the URL of the respurce
    NSURL *url = [NSURL fileURLWithPath:path];
    
    // Create a web view to display the help page
    UIWebView *webView = [[UIWebView alloc] init];
    webView.backgroundColor = [UIColor whiteColor];
    [webView loadRequest:[NSURLRequest requestWithURL:url]];
    
    UIViewController *viewController = [[AutorotatingViewController alloc] init];
    viewController.title = NSLocalizedString(title, nil);
    viewController.view = webView;
    [webView release];
    
    [self.navigationController pushViewController:viewController animated:YES];
    
    [viewController release];
}

@end
