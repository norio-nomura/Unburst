//
//  ALAssetRepresentation+Unburst.h
//  Unburst
//

#import <AssetsLibrary/AssetsLibrary.h>

/*!
 *  iOS Camera set Apple specific dictionary for key("{MakerApple}") in the metadata of photo.
 *  Burst Mode on iPhone 5s set value for key("11") in the Apple specific dictionary.
 *  The key ("11") prevent -[ALAssetsLibrary writeImageDataToSavedPhotosAlbum:] from creating new ALAssets into Camera Roll.
 */
@interface ALAssetRepresentation (Unburst)

/*!
 *  Is Apple specific dictionary contains value for key("11")?
 *
 *  @return YES or NO
 */
- (BOOL)unburst_hasBurstInfo;

/*!
 *  Return metadata which has been removed the key which prevent from creating new ALAssets into Camera Roll.
 *
 *  @return metadata
 */
- (NSDictionary*)unburst_getUnburstedMetadata;

@end
