//
//  DDXMLDocument+MKPAdditions.m
//  MiniKeePass
//
//  Created by Jason Rush on 9/15/12.
//  Copyright (c) 2012 Self. All rights reserved.
//

#import "DDXMLDocument+MKPAdditions.h"

@implementation DDXMLDocument (MKPAdditions)

- (id)initWithReadIO:(xmlInputReadCallback)ioread closeIO:(xmlInputCloseCallback)ioclose context:(void*)ioctx options:(NSUInteger)mask error:(NSError **)error {
	// Even though xmlKeepBlanksDefault(0) is called in DDXMLNode's initialize method,
	// it has been documented that this call seems to get reset on the iPhone:
	// http://code.google.com/p/kissxml/issues/detail?id=8
	//
	// Therefore, we call it again here just to be safe.
	xmlKeepBlanksDefault(0);

	xmlDocPtr doc = xmlReadIO(ioread, ioclose, ioctx, NULL, NULL, mask);
	if (doc == NULL) {
		if (error) {
            *error = [NSError errorWithDomain:@"DDXMLErrorDomain" code:1 userInfo:nil];
        }

		return nil;
	}

	return [self initWithDocPrimitive:doc owner:nil];
}

@end
