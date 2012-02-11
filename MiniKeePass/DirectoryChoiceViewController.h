//
//  DirectoryChoiceViewController.h
//  MiniKeePass
//
//  Created by John Flanagan on 2/1/12.
//  Copyright (c) 2012 Self. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <DropboxSDK/DropboxSDK.h>

#import "SettingsViewController.h"

@interface DirectoryChoiceViewController : UITableViewController <DBRestClientDelegate> {
    NSString *path;
    NSArray *directories;
    DBRestClient *restClient;
    SettingsViewController *settingsViewController;
}

- (id)initWithSettingsViewController:(SettingsViewController*)settingsView andPath:(NSString*)directoryPath;

@property (nonatomic, copy) NSString *path;

@end
