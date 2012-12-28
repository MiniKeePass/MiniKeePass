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

#import "Base64.h"

static const int8_t ENCODE_TABLE[] = {
    'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M',
    'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z',
    'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm',
    'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z',
    '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '+', '/'
};

static const int8_t DECODE_TABLE[] = {
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 62, -1, -1, -1, 63,
    52, 53, 54, 55, 56, 57, 58, 59, 60, 61, -1, -1, -1, -1, -1, -1,
    -1,  0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14,
    15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, -1, -1, -1, -1, -1,
    -1, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40,
    41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51
};

@implementation Base64

+ (NSMutableData*)encode:(NSData*)inputData {
    uint8_t *input = (uint8_t*)inputData.bytes;
    NSUInteger length = inputData.length;
    NSMutableData *outputData = [NSMutableData dataWithLength:((length + 2) / 3) * 4];
    uint8_t *output = (uint8_t*)outputData.mutableBytes;
    NSInteger index = 0;
    
    for (NSInteger i = 0; i < length; i += 3) {
        NSInteger value = 0;
        for (NSInteger j = i; j < (i + 3); j++) {
            value <<= 8;
            if (j < length) {
                value |= (0xFF & input[j]);
            }
        }
        
        output[index++] =                    ENCODE_TABLE[(value >> 18) & 0x3F];
        output[index++] =                    ENCODE_TABLE[(value >> 12) & 0x3F];
        output[index++] = (i + 1) < length ? ENCODE_TABLE[(value >> 6)  & 0x3F] : '=';
        output[index++] = (i + 2) < length ? ENCODE_TABLE[(value >> 0)  & 0x3F] : '=';
    }
    
    return outputData;
}

+ (NSMutableData*)decode:(NSData*)inputData {
    uint8_t *input = (uint8_t*)inputData.bytes;
    NSUInteger length = inputData.length;
    uint8_t output[length * 3 / 4];
    NSInteger index = 0;
    
    for (NSUInteger i = 0; i < length; i += 4) {
        char i0 = input[i];
        char i1 = i < length ? input[i + 1] : '=';
        char i2 = i < length ? input[i + 2] : '=';
        char i3 = i < length ? input[i + 3] : '=';
        
        if (i0 != '=' && i1 != '=') {
            output[index++] = (DECODE_TABLE[i0] << 2) | (DECODE_TABLE[i1] >> 4);
        }
        if (i1 != '=' && i2 != '=') {
            output[index++] = ((DECODE_TABLE[i1] & 0xf) << 4) | (DECODE_TABLE[i2] >> 2);
        }
        if (i2 != '=' && i3 != '=') {
            output[index++] = ((DECODE_TABLE[i2] & 0x3) << 6) | DECODE_TABLE[i3];
        }
    }
    
    return [NSMutableData dataWithBytes:output length:index];
}

@end
