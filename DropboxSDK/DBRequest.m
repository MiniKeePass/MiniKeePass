//
//  DBRestRequest.m
//  DropboxSDK
//
//  Created by Brian Smith on 4/9/10.
//  Copyright 2010 Dropbox, Inc. All rights reserved.
//

#import "DBRequest.h"
#import "DBError.h"
#import "JSON.h"


static id networkRequestDelegate = nil;

@implementation DBRequest

+ (void)setNetworkRequestDelegate:(id<DBNetworkRequestDelegate>)delegate {
    networkRequestDelegate = delegate;
}

- (id)initWithURLRequest:(NSURLRequest*)aRequest andInformTarget:(id)aTarget selector:(SEL)aSelector {
    if ((self = [super init])) {
        request = [aRequest retain];
        target = aTarget;
        selector = aSelector;
        
        urlConnection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
        [networkRequestDelegate networkRequestStarted];
    }
    return self;
}

- (void) dealloc {
    [urlConnection cancel];
	
    [request release];
    [urlConnection release];
    [fileHandle release];
    [userInfo release];
    [response release];
    [resultFilename release];
    [tempFilename release];
    [resultData release];
    [error release];
    [super dealloc];
}

@synthesize failureSelector;
@synthesize downloadProgressSelector;
@synthesize uploadProgressSelector;
@synthesize userInfo;
@synthesize request;
@synthesize response;
@synthesize downloadProgress;
@synthesize uploadProgress;
@synthesize resultData;
@synthesize resultFilename;
@synthesize error;

- (NSString*)resultString {
    return [[[NSString alloc] 
             initWithData:resultData encoding:NSUTF8StringEncoding]
            autorelease];
}

- (NSObject*)resultJSON {
    return [[self resultString] JSONValue];
} 

- (NSInteger)statusCode {
    return [response statusCode];
}

- (void)cancel {
    [urlConnection cancel];
    target = nil;
    
    if (tempFilename) {
        [fileHandle closeFile];
        NSError* rmError;
        if (![[NSFileManager defaultManager] removeItemAtPath:tempFilename error:&rmError]) {
            NSLog(@"DBRequest#cancel Error removing temp file: %@", rmError);
        }
    }
    
    [networkRequestDelegate networkRequestStopped];
}

#pragma mark NSURLConnection delegate methods

- (void)connection:(NSURLConnection*)connection didReceiveResponse:(NSURLResponse*)aResponse {
    response = [(NSHTTPURLResponse*)aResponse retain];
    
    if (resultFilename && [self statusCode] == 200) {
        // Create the file here so it's created in case it's zero length
        // File is downloaded into a temporary file and then moved over when completed successfully
        NSString* filename = 
            [NSString stringWithFormat:@"%.0f", 1000*[NSDate timeIntervalSinceReferenceDate]];
        tempFilename = [[NSTemporaryDirectory() stringByAppendingPathComponent:filename] retain];
        
        NSFileManager* fileManager = [[NSFileManager new] autorelease];
        BOOL success = [fileManager createFileAtPath:tempFilename contents:nil attributes:nil];
        if (!success) {
            NSLog(@"DBRequest#connection:didReceiveData: Error creating file at path: %@", 
                    tempFilename);
        }

        fileHandle = [[NSFileHandle fileHandleForWritingAtPath:tempFilename] retain];
    }
}

- (void)connection:(NSURLConnection*)connection didReceiveData:(NSData*)data {
    if (resultFilename && [self statusCode] == 200) {
        @try {
            [fileHandle writeData:data];
        } @catch (NSException* e) {
            // In case we run out of disk space
            [urlConnection cancel];
            [fileHandle closeFile];
            [[NSFileManager defaultManager] removeItemAtPath:tempFilename error:nil];
            error = [[NSError alloc] initWithDomain:DBErrorDomain
                                        code:DBErrorInsufficientDiskSpace userInfo:userInfo];
            
            SEL sel = failureSelector ? failureSelector : selector;
            [target performSelector:sel withObject:self];
            
            [networkRequestDelegate networkRequestStopped];
            
            return;
        }
    } else {
        if (resultData == nil) {
            resultData = [NSMutableData new];
        }
        [resultData appendData:data];
    }
    
    bytesDownloaded += [data length];
    NSInteger contentLength = [[[response allHeaderFields] objectForKey:@"Content-Length"] intValue];
    downloadProgress = (CGFloat)bytesDownloaded / (CGFloat)contentLength;
    if (downloadProgressSelector) {
        [target performSelector:downloadProgressSelector withObject:self];
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection*)connection {
    [fileHandle closeFile];
    [fileHandle release];
    fileHandle = nil;
    
    if (self.statusCode != 200) {
        NSMutableDictionary* errorUserInfo = [NSMutableDictionary dictionaryWithDictionary:userInfo];
        // To get error userInfo, first try and make sense of the response as JSON, if that
        // fails then send back the string as an error message
        NSString* resultString = [self resultString];
        if ([resultString length] > 0) {
            @try {
                SBJsonParser *jsonParser = [SBJsonParser new];
                NSObject* resultJSON = [jsonParser objectWithString:resultString];
                [jsonParser release];
                
                if ([resultJSON isKindOfClass:[NSDictionary class]]) {
                    [errorUserInfo addEntriesFromDictionary:(NSDictionary*)resultJSON];
                }
            } @catch (NSException* e) {
                [errorUserInfo setObject:resultString forKey:@"errorMessage"];
            }
        }
        error = [[NSError alloc] initWithDomain:@"dropbox.com" code:self.statusCode userInfo:errorUserInfo];
    } else if (tempFilename) {
        // Move temp file over to desired file
        NSFileManager* fileManager = [[NSFileManager new] autorelease];
        [fileManager removeItemAtPath:resultFilename error:nil];
        NSError* moveError;
        BOOL success = [fileManager moveItemAtPath:tempFilename toPath:resultFilename error:&moveError];
        if (!success) {
            NSLog(@"DBRequest#connectionDidFinishLoading: error moving temp file to desired location: %@",
                [moveError localizedDescription]);
            error = [[NSError alloc] initWithDomain:moveError.domain code:moveError.code userInfo:self.userInfo];
        }
        
        [tempFilename release];
        tempFilename = nil;
    }
    
    SEL sel = (error && failureSelector) ? failureSelector : selector;
    [target performSelector:sel withObject:self];
    
    [networkRequestDelegate networkRequestStopped];
}

- (void)connection:(NSURLConnection*)connection didFailWithError:(NSError*)anError {
    [fileHandle closeFile];
    error = [[NSError alloc] initWithDomain:anError.domain code:anError.code userInfo:self.userInfo];
    bytesDownloaded = 0;
    downloadProgress = 0;
    uploadProgress = 0;
    
    if (tempFilename) {
        NSFileManager* fileManager = [[NSFileManager new] autorelease];
        NSError* removeError;
        BOOL success = [fileManager removeItemAtPath:tempFilename error:&removeError];
        if (!success) {
            NSLog(@"DBRequest#connection:didFailWithError: error removing temporary file: %@", 
                    [removeError localizedDescription]);
        }
        [tempFilename release];
        tempFilename = nil;
    }
    
    SEL sel = failureSelector ? failureSelector : selector;
    [target performSelector:sel withObject:self];

    [networkRequestDelegate networkRequestStopped];
}

- (void)connection:(NSURLConnection*)connection didSendBodyData:(NSInteger)bytesWritten 
    totalBytesWritten:(NSInteger)totalBytesWritten 
    totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite {
    
    uploadProgress = (CGFloat)totalBytesWritten / (CGFloat)totalBytesExpectedToWrite;
    if (uploadProgressSelector) {
        [target performSelector:uploadProgressSelector withObject:self];
    }
}

@end
