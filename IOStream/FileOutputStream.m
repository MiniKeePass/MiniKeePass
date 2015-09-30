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

#import "FileOutputStream.h"

@implementation FileOutputStream

- (id)initWithFilename:(NSString*)filename flags:(int)flags mode:(mode_t)mode {
    self = [super init];
    if (self) {
        fd = open([filename UTF8String], flags, mode);
        if (fd == -1) {
            @throw [NSException exceptionWithName:@"IOException" reason:@"Failed to open file" userInfo:nil];
        }
    }
    return self;
}

- (void)dealloc {
    [self close];
}

- (NSUInteger)write:(const void *)bytes length:(NSUInteger)bytesLength {
    return write(fd, bytes, bytesLength);
}

- (off_t)seek:(off_t)offset {
    return lseek(fd, offset, SEEK_SET);
}

- (void)close {
    if (fd == -1) {
        return;
    }
    close(fd);
    fd = -1;
}

@end
