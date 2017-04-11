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

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef void (^DMrequestCallback)(NSError *);

enum {
    DropboxOK,
    DropboxNotInitiatized,
    DropboxNotAuthorized,
    DropboxUserCanceled,
    DropboxError,
    DropboxNotHandled
};

@interface DropboxManager : NSObject

+ (DropboxManager *)sharedInstance;
- (void) initDropboxAPI;
-(void) getAccountAuthorization:(UIApplication*)app controller:(UIViewController*)controller;
-(uint32_t) accountAuthorizationRedirect:(NSURL*)url;
-(void) resetAccount;

-(void) loadDropboxFileList:(DMrequestCallback)requestCallback;
-(NSMutableArray *) getDropboxFileList;
-(NSDate *) getDropboxFileModifiedDate:(NSString*)file;
-(void) downloadDropboxFile:(NSString*)path requestCallback:(DMrequestCallback)requestCallback;
-(void) uploadDropboxFile:(NSString*)path requestCallback:(DMrequestCallback)requestCallback;

/// Factory Methods to get paths and URLs.
- (NSString *)getLocalPath:(NSString *)filename;
- (NSURL *)getLocalURL:(NSString *)filename;
- (NSString *)getDropboxPath:(NSString *)filename;
- (NSString *)getDropboxTempDir;

@end
