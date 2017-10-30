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

#import "FileInputStream.h"

#include <fcntl.h>

@implementation FileInputStream

- (id)initWithFilename:(NSString *)filename {
    self = [super init];
    if (self) {
        fd = open([filename UTF8String], O_RDONLY);
        if (fd == -1) {
            @throw [NSException exceptionWithName:@"IOException" reason:@"Failed to open file" userInfo:nil];
        }
    }
    return self;
}

- (void)dealloc {
    [self close];
}

- (NSUInteger)read:(void *)bytes length:(NSUInteger)bytesLength {
    return read(fd, bytes, bytesLength);
}

- (off_t)seek:(off_t)offset {
    return lseek(fd, offset, SEEK_SET);
}

- (off_t)getpos {
    // Return the current file position
    return lseek(fd, 0, SEEK_CUR);
}

- (void)close {
    if (fd == -1) {
        return;
    }
    close(fd);
    fd = -1;
}

@end
