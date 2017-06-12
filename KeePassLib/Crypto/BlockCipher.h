/*
 * Copyright 2017 Jason Rush and John Flanagan. All rights reserved.
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

@interface BlockCipher : NSObject {
    uint8_t*  blockBuf;
    uint32_t  blockSize;
    uint32_t  blockPos;
}

- (id)init;
- (uint32_t)getBlockSize;
- (void)invalidateBlock;
- (void)NextBlock:(uint8_t*)buf;
- (void)Encrypt:(NSMutableData*)m;  // Use zero offset and whole length of m
- (void)Encrypt:(void*)pb iOffset:(size_t)iOffset count:(size_t)cb;

- (void)Decrypt:(NSMutableData*)m;
- (void)Decrypt:(void*)pb iOffset:(size_t)iOffset count:(size_t)cb;

@end
