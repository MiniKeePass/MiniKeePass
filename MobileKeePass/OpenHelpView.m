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

#import "OpenHelpView.h"
#import "MobileKeePassAppDelegate.h"

@implementation OpenHelpView

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.backgroundColor = [UIColor groupTableViewBackgroundColor];
        
        UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"connect.png"]];
        imageView.frame = CGRectMake(94, 16, 131, 98);
        [self addSubview:imageView];
        [imageView release];

        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 130, 320, 40)];
        label.backgroundColor = [UIColor clearColor];
        label.textAlignment = UITextAlignmentCenter;
        label.numberOfLines = 0;
        label.lineBreakMode = UILineBreakModeWordWrap;
        label.text = @"You do not have any KeePass files available for MobileKeePass to open.";
        [self addSubview:label];
        [label release];
        
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.frame = CGRectMake(0, 186, 320, 20);
        [button setTitle:@"Sync with iTunes" forState:UIControlStateNormal];
        [button setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
        [button setTitleColor:[UIColor redColor] forState:UIControlStateHighlighted];
        [button addTarget:self action:@selector(iTunesPressed:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:button];
        
        button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.frame = CGRectMake(0, 222, 320, 20);
        [button setTitle:@"Sync with Dropbox" forState:UIControlStateNormal];
        [button setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
        [button setTitleColor:[UIColor redColor] forState:UIControlStateHighlighted];
        [button addTarget:self action:@selector(dropboxPressed:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:button];
    }
    return self;
}

- (void)dealloc {
    [super dealloc];
}

- (void)pushWebView:(NSString*)resource {
    UIWebView *webView = [[UIWebView alloc] init];
	webView.backgroundColor = [UIColor whiteColor];
    
    NSURL *url = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:resource ofType:@"html"]];
    [webView loadRequest:[NSURLRequest requestWithURL:url]];
    
    UIViewController *viewController = [[UIViewController alloc] init];
    viewController.view = webView;
    [webView release];
    
    MobileKeePassAppDelegate *appDelegate = (MobileKeePassAppDelegate*)[[UIApplication sharedApplication] delegate];
    [appDelegate.navigationController pushViewController:viewController animated:YES];
    [viewController release];
}

- (void)iTunesPressed:(id)sender {
    [self pushWebView:@"itunes"];
}

- (void)dropboxPressed:(id)sender {
    [self pushWebView:@"dropbox"];
}

@end
