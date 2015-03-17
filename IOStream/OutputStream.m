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

#import "OutputStream.h"

@implementation OutputStream

- (NSUInteger)write:(const void *)bytes length:(NSUInteger)bytesLength {
    [self doesNotRecognizeSelector:_cmd];
    return 0;
}

- (NSUInteger)write:(NSData *)data {
    return [self write:[data bytes] length:[data length]];
}

- (void)writeInt8:(uint8_t)value {
    [self write:&value length:1];
}

- (void)writeInt16:(uint16_t)value {
    [self write:&value length:2];
}

- (void)writeInt32:(uint32_t)value {
    [self write:&value length:4];
}

- (void)writeInt64:(uint64_t)value {
    [self write:&value length:8];
}

- (void)close {
    
}

@end
