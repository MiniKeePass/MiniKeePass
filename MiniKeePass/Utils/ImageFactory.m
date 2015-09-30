/*
 * Copyright 2011-2013 Jason Rush and John Flanagan. All rights reserved.
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

#import "ImageFactory.h"

#define NUM_IMAGES 69

@interface ImageFactory ()
@property (nonatomic, strong) NSMutableArray *standardImages;
@end

@implementation ImageFactory

- (id)init {
    self = [super init];
    if (self) {
        self.standardImages = [[NSMutableArray alloc] initWithCapacity:NUM_IMAGES];
        for (NSUInteger i = 0; i < NUM_IMAGES; i++) {
            [self.standardImages addObject:[NSNull null]];
        }
    }
    return self;
}

+ (ImageFactory *)sharedInstance {
    static ImageFactory *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[ImageFactory alloc] init];
    });
    return sharedInstance;
}

- (NSArray *)images {
    // Make sure all the standard images are loaded
    for (NSUInteger i = 0; i < NUM_IMAGES; i++) {
        [self imageForIndex:i];
    }
    return self.standardImages;
}

- (UIImage *)imageForGroup:(KdbGroup *)group {
    return [self imageForIndex:group.image];
}

- (UIImage *)imageForEntry:(KdbEntry *)entry {
    return [self imageForIndex:entry.image];
}

- (UIImage *)imageForIndex:(NSInteger)index {
    if (index >= NUM_IMAGES) {
        return nil;
    }

    id image = [self.standardImages objectAtIndex:index];
    if (image == [NSNull null]) {
        image = [UIImage imageNamed:[NSString stringWithFormat:@"%ld", (long)index]];
        [self.standardImages replaceObjectAtIndex:index withObject:image];
    }

    return image;
}

@end
