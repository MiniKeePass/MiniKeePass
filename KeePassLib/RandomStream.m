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

#import "RandomStream.h"

@implementation RandomStream

- (void)reset {
    [self doesNotRecognizeSelector:_cmd];
}

- (uint8_t)getByte {
    [self doesNotRecognizeSelector:_cmd];
    return 0;
}

- (uint16_t)getShort {
    uint16_t value = 0;
    
    value |= [self getByte] << 8;
    value |= [self getByte];
    
    return value;
}

- (uint32_t)getInt {
    uint32_t value = 0;
    
    value |= [self getByte] << 24;
    value |= [self getByte] << 16;
    value |= [self getByte] << 8;
    value |= [self getByte];
    
    return value;
}

- (void)xor:(NSMutableData*)data {
    uint8_t *bytes = (uint8_t*)data.mutableBytes;
    NSUInteger length = data.length;
    
    for (int i = 0; i < length; i++) {
        bytes[i] ^= [self getByte];
    }
}

@end
