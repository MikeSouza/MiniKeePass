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
#import "Kdb4Node.h"
#import "UUID.h"

#define NUM_IMAGES 69
#define SIZE_1X 24

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

- (UIImage *)imageForGroup:(KdbGroup *)group fromTree:(KdbTree *)tree {
    if ([group isKindOfClass:[Kdb4Group class]] && tree != nil) {
        Kdb4Group *kdb4Group = (Kdb4Group *)group;
        if (kdb4Group.customIconUuid != nil) {
            Kdb4Tree *kdb4Tree = (Kdb4Tree *)tree;
            return [self customImageForUuid:kdb4Group.customIconUuid fromTree:kdb4Tree];
        }
    }
    return [self imageForIndex:group.image];
}

- (UIImage *)imageForEntry:(KdbEntry *)entry fromTree:(KdbTree *)tree {
    if ([entry isKindOfClass:[Kdb4Entry class]] && tree != nil) {
        Kdb4Entry *kdb4Entry = (Kdb4Entry *)entry;
        if (kdb4Entry.customIconUuid != nil) {
            Kdb4Tree *kdb4Tree = (Kdb4Tree *)tree;
            return [self customImageForUuid:kdb4Entry.customIconUuid fromTree:kdb4Tree];
        }
    }
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

- (UIImage *) customImageForUuid:(UUID *)customIconUuid fromTree:(Kdb4Tree *)tree {
    if (tree == nil || tree.customIcons.count == 0)
        return nil;

    for (CustomIcon *customIcon in tree.customIcons) {
        if ([customIcon.uuid isEqual:customIconUuid]) {
            NSData *decodedImageData = [[NSData alloc]initWithBase64EncodedString:customIcon.data options:NSDataBase64DecodingIgnoreUnknownCharacters];
            
            UIImage *originalImage = [UIImage imageWithData:decodedImageData];
            
            CGSize size;
            size.height = SIZE_1X;
            size.width = SIZE_1X;
            
            UIImage *scaledImage = [self imageResize:originalImage andResizeTo:size];
            return scaledImage;
        }
    }

    return nil;
}

- (UIImage *)imageResize:(UIImage*)originalImage andResizeTo:(CGSize)newSize
{
    // Avoid redundant drawing
    if (CGSizeEqualToSize(originalImage.size, newSize)) {
        return originalImage;
    }
    
    CGFloat scale = [[UIScreen mainScreen] scale];
    
    // Create drawing context
    UIGraphicsBeginImageContextWithOptions(newSize, NO, scale);
    
    // Draw
    [originalImage drawInRect:CGRectMake(0.0f, 0.0f, newSize.width, newSize.height)];
    
    // Capture resulting image
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return newImage;
}

@end
