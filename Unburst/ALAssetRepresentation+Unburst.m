//
//  ALAssetRepresentation+Unburst.m
//  Unburst
//

#import "ALAssetRepresentation+Unburst.h"

@implementation ALAssetRepresentation (Unburst)

/*!
 *  Key for Apple metadata.
 */
static NSString * const kMakerApple = @"{MakerApple}";
/*!
 *  Key for metadata which indicates the photo is taken by Burst Mode.
 */
static NSString * const kGUIDKey = @"11";

- (BOOL)unburst_hasBurstInfo;
{
    return nil != self.metadata[kMakerApple][kGUIDKey];
}

- (NSDictionary*)unburst_getUnburstedMetadata;
{
    if ([self unburst_hasBurstInfo]) {
        NSDictionary *original = self.metadata;
        NSMutableDictionary *metadata = [NSMutableDictionary dictionaryWithCapacity:original.count];
        for (id key in original.allKeys) {
            if ([key isEqual:kMakerApple]) {
                NSMutableDictionary *makerApple = [original[key]mutableCopy];
                [makerApple removeObjectForKey:kGUIDKey];
                metadata[key] = makerApple;
            } else {
                metadata[key] = original[key];
            }
        }
        return metadata;
    } else {
        return self.metadata;
    }
}

@end
