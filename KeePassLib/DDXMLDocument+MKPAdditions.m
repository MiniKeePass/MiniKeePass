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

#import "DDXMLDocument+MKPAdditions.h"

@implementation DDXMLDocument (MKPAdditions)

- (id)initWithReadIO:(xmlInputReadCallback)ioread closeIO:(xmlInputCloseCallback)ioclose context:(void*)ioctx options:(NSUInteger)mask error:(NSError **)error {
	// Even though xmlKeepBlanksDefault(0) is called in DDXMLNode's initialize method,
	// it has been documented that this call seems to get reset on the iPhone:
	// http://code.google.com/p/kissxml/issues/detail?id=8
	//
	// Therefore, we call it again here just to be safe.
	xmlKeepBlanksDefault(0);

	xmlDocPtr doc = xmlReadIO(ioread, ioclose, ioctx, NULL, NULL, (int)mask);
	if (doc == NULL) {
		if (error) {
            *error = [NSError errorWithDomain:@"DDXMLErrorDomain" code:1 userInfo:nil];
        }

		return nil;
	}

	return [self initWithDocPrimitive:doc owner:nil];
}

@end
