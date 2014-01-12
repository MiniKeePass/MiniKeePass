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
#import "MiniKeePassAppDelegate.h"
#import "Kdb4Node.h"

#define NUM_IMAGES 69

@implementation KdbImage

+ (KdbImage *)kdbImageWithImage:(UIImage *)image andIndex:(NSUInteger)index {
    KdbImage *kdbImage = [[KdbImage alloc] init];
    kdbImage.image = image;
    kdbImage.index = index;
    kdbImage.uuid = nil;
    return kdbImage;
}

+ (KdbImage *)kdbImageWithImage:(UIImage *)image andUuid:(UUID *)uuid {
    KdbImage *kdbImage = [[KdbImage alloc] init];
    kdbImage.image = image;
    kdbImage.index = NSUIntegerMax;
    kdbImage.uuid = uuid;
    return kdbImage;
}

+ (KdbImage *)kdbImageForEntry:(KdbEntry *)entry {
    KdbImage *kdbImage = [[KdbImage alloc] init];

    if ([entry isKindOfClass:[Kdb4Entry class]]) {
        kdbImage.uuid = ((Kdb4Entry *)entry).customIconUuid;
    }

    if (kdbImage.uuid == nil) {
        kdbImage.index = entry.image;
    }

    ImageFactory *imageFactory = [ImageFactory sharedInstance];
    if (kdbImage.uuid != nil) {
        kdbImage.image = [imageFactory imageForUuid:kdbImage.uuid];
    } else if (kdbImage.index != NSUIntegerMax) {
        kdbImage.image = [imageFactory imageForIndex:kdbImage.index];
    }

    return kdbImage;
}

+ (KdbImage *)kdbImageForGroup:(KdbGroup *)group {
    KdbImage *kdbImage = [[KdbImage alloc] init];

    if ([group isKindOfClass:[Kdb4Group class]]) {
        kdbImage.uuid = ((Kdb4Group *)group).customIconUuid;
    }

    if (kdbImage.uuid == nil) {
        kdbImage.index = group.image;
    }

    ImageFactory *imageFactory = [ImageFactory sharedInstance];
    if (kdbImage.uuid != nil) {
        kdbImage.image = [imageFactory imageForUuid:kdbImage.uuid];
    } else if (kdbImage.index != NSUIntegerMax) {
        kdbImage.image = [imageFactory imageForIndex:kdbImage.index];
    }

    return kdbImage;
}

- (BOOL)isEqual:(id)object {
    if (![object isKindOfClass:[KdbImage class]]) {
        return NO;
    }

    KdbImage *kdbImage = object;
    if (self.uuid != nil || kdbImage.uuid != nil) {
        // If either has a UUID, make sure it matches
        if (self.uuid != nil && kdbImage.uuid != nil) {
            return [kdbImage.uuid isEqual:self.uuid];
        }
    } else {
        return kdbImage.index == self.index;
    }

    return NO;
}

@end

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

- (NSArray *)kdbImages {
    NSMutableArray *kdbImages = [[NSMutableArray alloc] init];

    // Make sure all the standard images are loaded
    for (NSUInteger i = 0; i < NUM_IMAGES; i++) {
        KdbImage *kdbImage = [KdbImage kdbImageWithImage:[self imageForIndex:i] andIndex:i];
        [kdbImages addObject:kdbImage];
    }

    MiniKeePassAppDelegate *appDelegate = [MiniKeePassAppDelegate appDelegate];
    KdbTree *kdbTree = appDelegate.databaseDocument.kdbTree;
    if ([kdbTree isKindOfClass:[Kdb4Tree class]]) {
        NSArray *customIcons = ((Kdb4Tree *)kdbTree).customIcons;
        for (CustomIcon *customIcon in customIcons) {
            KdbImage *kdbImage = [KdbImage kdbImageWithImage:customIcon.image andUuid:customIcon.uuid];
            [kdbImages addObject:kdbImage];
        }
    }

    return kdbImages;
}

- (UIImage *)imageForGroup:(KdbGroup *)group {
    UIImage *image = nil;

    if ([group isKindOfClass:[Kdb4Group class]]) {
        UUID *customIconUuid = ((Kdb4Group *)group).customIconUuid;
        if (customIconUuid != nil) {
            image = [self imageForUuid:customIconUuid];
        }
    }

    if (image == nil) {
        image = [self imageForIndex:group.image];
    }

    return image;
}

- (UIImage *)imageForEntry:(KdbEntry *)entry {
    UIImage *image = nil;

    if ([entry isKindOfClass:[Kdb4Entry class]]) {
        UUID *customIconUuid = ((Kdb4Entry *)entry).customIconUuid;
        if (customIconUuid != nil) {
             image = [self imageForUuid:customIconUuid];
        }
    }

    if (image == nil) {
        image = [self imageForIndex:entry.image];
    }

    return image;
}

- (UIImage *)imageForUuid:(UUID *)uuid {
    MiniKeePassAppDelegate *appDelegate = [MiniKeePassAppDelegate appDelegate];
    KdbTree *kdbTree = appDelegate.databaseDocument.kdbTree;
    if ([kdbTree isKindOfClass:[Kdb4Tree class]]) {
        NSArray *customIcons = ((Kdb4Tree *)kdbTree).customIcons;
        for (CustomIcon *customIcon in customIcons) {
            if ([customIcon.uuid isEqual:uuid]) {
                return customIcon.image;
            }
        }
    }

    return nil;
}

- (UIImage *)imageForIndex:(NSUInteger)index {
    if (index >= NUM_IMAGES) {
        return nil;
    }

    id image = [self.standardImages objectAtIndex:index];
    if (image == [NSNull null]) {
        image = [UIImage imageNamed:[NSString stringWithFormat:@"%d", index]];
        [self.standardImages replaceObjectAtIndex:index withObject:image];
    }

    return image;
}

@end
