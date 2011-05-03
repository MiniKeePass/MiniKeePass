//
//  FileViewController.h
//  MobileKeePass
//
//  Created by Jason Rush on 5/1/11.
//  Copyright 2011 Self. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PasswordEntryController.h"

@interface FileViewController : UITableViewController <PasswordEntryControllerDelegate> {
    NSArray *files;
    NSString *selectedFile;
}

@end
