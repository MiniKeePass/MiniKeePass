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

#import "DropboxManager.h"
#import "DropboxDocument.h"
#import "AppSettings.h"

@interface DropboxDocument ()
@property (nonatomic, strong) KdbPassword *kdbPassword;
@end

@implementation DropboxDocument

/*
- (id)initWithFilename:(NSString *)filename password:(NSString *)password keyFile:(NSString *)keyFile {
    self = [super init];
    if (self) {
        if (password == nil && keyFile == nil) {
            @throw [NSException exceptionWithName:@"IllegalArgument"
                                           reason:NSLocalizedString(@"No password or keyfile specified", nil)
                                         userInfo:nil];
        }

        self.filename = filename;

        NSStringEncoding passwordEncoding = [[AppSettings sharedInstance] passwordEncoding];
        self.kdbPassword = [[KdbPassword alloc] initWithPassword:password
                                                passwordEncoding:passwordEncoding
                                                         keyFile:keyFile];
        
        self.kdbTree = [KdbReaderFactory load:self.filename withPassword:self.kdbPassword];
    }
    return self;
}

*/

- (void)save {
    printf("Saving dropbox temp file..\n");
    [KdbWriterFactory persist:self.kdbTree file:self.filename withPassword:self.kdbPassword];
    
    // Update the file on dropbox.
    NSString *fileOnly = [self.filename lastPathComponent];
    [[DropboxManager sharedInstance] uploadFile:fileOnly requestCallback:^(NSError *error) {
        if( error != nil ) {
            NSLog( @"%@\n", error.description);
        }
    }];
}

@end
