//
//  DirectoryChoiceViewController.h
//  MiniKeePass
//
//  Created by John Flanagan on 2/1/12.
//  Copyright (c) 2012 Self. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <DropboxSDK/DropboxSDK.h>

@interface DirectoryChoiceViewController : UITableViewController <DBRestClientDelegate> {
    NSString *path;
    NSArray *directories;
    DBRestClient *restClient;
}

- (id)initWithPath:(NSString*)directoryPath;

@property (nonatomic, copy) NSString *path;

@end
