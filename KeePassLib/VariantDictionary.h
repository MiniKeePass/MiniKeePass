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
#import "InputStream.h"

@interface VariantDictionary : NSObject {
    NSMutableDictionary *dict;
    NSMutableDictionary *type;
}

- (id)init;

- (id)objectForKeyedSubscript:(id)key;

- (void)addUInt32:(uint32_t)value forKey:(NSString*)key;
- (void)addUInt64:(uint64_t)value forKey:(NSString*)key;
- (void)addBool:(BOOL)value forKey:(NSString*)key;
- (void)addInt32:(int32_t)value forKey:(NSString*)key;
- (void)addInt64:(int64_t)value forKey:(NSString*)key;
- (void)addString:(NSString*)string forKey:(NSString*)key;
- (void)addByteArray:(NSData*)data forKey:(NSString*)key;

- (void)deserialize:(InputStream*)data;
- (NSData*)serialize;
- (NSUInteger)count;

@end
