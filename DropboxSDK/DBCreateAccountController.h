//
//  DBCreateAccountController.h
//  DropboxSDK
//
//  Created by Brian Smith on 5/20/10.
//  Copyright 2010 Dropbox, Inc. All rights reserved.
//


@class DBLoadingView;
@class DBLoginController;
@class DBRestClient;

@interface DBCreateAccountController : UIViewController {
    BOOL hasCreatedAccount;
    DBLoginController* loginController;
    DBRestClient* restClient;
    
    UITableView* tableView;
    UIView* headerView;
    UITableViewCell* firstNameCell;
    UITextField* firstNameField;
    UITableViewCell* lastNameCell;
    UITextField* lastNameField;
    UITableViewCell* emailCell;
    UITextField* emailField;
    UITableViewCell* passwordCell;
    UITextField* passwordField;
    UIView* footerView;
    UIActivityIndicatorView* activityIndicator;
    DBLoadingView* loadingView;
}

@property (nonatomic, assign) DBLoginController* loginController;

@end
