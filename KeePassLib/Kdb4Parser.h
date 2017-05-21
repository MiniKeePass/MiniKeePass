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
#import "Kdb4Node.h"
#import "RandomStream.h"
#import "InputStream.h"

@interface Kdb4Parser : NSObject {
    Kdb4Tree *tree;
    RandomStream *randomStream;
    NSDateFormatter *dateFormatter;
}

- (id)initWithRandomStream:(RandomStream*)cryptoRandomStream;
- (Kdb4Tree*)parse:(InputStream*)inputStream dbVersion:(uint32_t)dbVersion;

@end
