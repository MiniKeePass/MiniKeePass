/*
 * Copyright 2017 Tait Smith. All rights reserved.
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

typedef void (^CMrequestCallback)(NSError *);

enum {
    CloudManager_OK,
    CloudManager_NotInitiatized,
    CloudManager_NotAuthorized,
    CloudManager_UserCanceled,
    CloudManager_Error,
    CloudManager_NotHandled
};

@interface CloudManager : NSObject

+(CloudManager *)sharedInstance;
-(void) initAPI;
-(BOOL) isClientAuthorized;
-(BOOL) getAccountAuthorization:(UIApplication*)app controller:(UIViewController*)controller;
-(uint32_t) accountAuthorizationRedirect:(NSURL*)url;
-(void) resetAccount;

-(void) loadFileList:(CMrequestCallback)requestCallback;
-(NSMutableArray *) getFileList;
-(NSDate *) getFileModifiedDate:(NSString*)file;
-(void) downloadFile:(NSString*)path requestCallback:(CMrequestCallback)requestCallback;
-(void) uploadFile:(NSString*)path requestCallback:(CMrequestCallback)requestCallback;

// Factory Methods to get paths and URLs.
-(NSString *)getLocalPath:(NSString *)filename;
-(NSURL *)getLocalURL:(NSString *)filename;
-(NSString *)getRemotePath:(NSString *)filename;
-(NSString *)getTempDir;

@end

