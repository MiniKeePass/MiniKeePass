/*
 * Copyright 2011-2014 Jason Rush and John Flanagan. All rights reserved.
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

#import "CustomHttpProtocol.h"

@interface CustomHttpProtocol () <NSURLConnectionDelegate, NSURLConnectionDataDelegate>

@property (nonatomic, strong) NSURLConnection *connection;

@end

@implementation CustomHttpProtocol

static NSString * const kCustomRequestProperty = @"com.jflan.minikeepass.CustomHttpProtocol";
__weak static id<CustomHttpProtocolDelegate> protocolDelegate;

+ (void)registerProtocol {
    [NSURLProtocol registerClass:self];
}

+ (void)setProtocolDelegate:(id<CustomHttpProtocolDelegate>)delegate {
    protocolDelegate = delegate;
}

+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
    // Don't process requests recursively
    if ([self propertyForKey:kCustomRequestProperty inRequest:request] != nil) {
        return NO;
    }

    // Check if the scheme is HTTP(S)
    NSString *scheme = [request.URL.scheme lowercaseString];
    BOOL result = [scheme isEqual:@"http"] || [scheme isEqual:@"https"];

    return result;
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
    // FIXME What's canonical? :)
    return request;
}

- (id)initWithRequest:(NSURLRequest *)request cachedResponse:(NSCachedURLResponse *)cachedResponse client:(id<NSURLProtocolClient>)client {
    NSMutableURLRequest *newRequest = (NSMutableURLRequest*)request;
    [NSURLProtocol setProperty:@YES forKey:kCustomRequestProperty inRequest:newRequest];

    return [super initWithRequest:newRequest cachedResponse:cachedResponse client:client];
}

- (void)startLoading {
    // Create a new connection with the request and ourselves as the delegate
    self.connection = [[NSURLConnection alloc] initWithRequest:self.request delegate:self];
}

- (void)stopLoading {
    // Stop the connection
    if (self.connection != nil) {
        [self.connection cancel];
        self.connection = nil;
    }
}

#pragma mark - NSURLConnection delegate

- (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)response {
    // Check if there is a redirect response
    if (response != nil) {
        // Remove the custom header property
        NSMutableURLRequest *redirectRequest = [self.request mutableCopy];
        [NSURLProtocol removePropertyForKey:kCustomRequestProperty inRequest:redirectRequest];

        // Notify the client of the redirect
        [self.client URLProtocol:self wasRedirectedToRequest:redirectRequest redirectResponse:response];

        // Cancel the connection
        [self.connection cancel];
        [self.client URLProtocol:self didFailWithError:[NSError errorWithDomain:NSCocoaErrorDomain code:NSUserCancelledError userInfo:nil]];
    }

    return request;
}


- (BOOL)connectionShouldUseCredentialStorage:(NSURLConnection *)connection {
    return YES;
}

- (void)connection:(NSURLConnection *)connection willSendRequestForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    if (protocolDelegate != nil && [protocolDelegate respondsToSelector:@selector(customHttpProtocol:willSendRequestForAuthenticationChallenge:)]) {
        [protocolDelegate customHttpProtocol:self willSendRequestForAuthenticationChallenge:challenge];
    }
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse {
    return cachedResponse;
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [self.client URLProtocol:self didLoadData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    [self.client URLProtocolDidFinishLoading:self];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    [self.client URLProtocol:self didFailWithError:error];
}

@end
