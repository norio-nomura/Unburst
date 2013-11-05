//
//  PreviewItem.h
//  Unburst
//

#import <Foundation/Foundation.h>
#import <QuickLook/QuickLook.h>


@class ALAsset;

@protocol PreviewItemDelegate;

/*!
 *  PreviewItem for QLPreviewController
 */
@interface PreviewItem : NSObject<QLPreviewItem>

/*!
 *  Property conforms to QLPreviewItem
 */
@property (readonly) NSURL *previewItemURL;

/*!
 *  identifying the asset
 */
@property (readonly, nonatomic) NSURL *assetURL;

/*!
 *  Return PreviewItem instance for asset.
 *
 *  If PreviewItem has been created for asset.defaultRepresentation.url previously, return it.
 *
 *  @param delegate will be notified on `previewItem:updatedURL:`.
 *  @param asset ALAsset should be passed
 *
 *  @return PreviewItem
 */
+ (instancetype)previewItemWithDelegate:(id<PreviewItemDelegate>)delegate forAsset:(ALAsset*)asset;

@end

@protocol PreviewItemDelegate <NSObject>

/*!
 *  This method will be called by PreviewItem when previewItemURL will be ready.
 *
 *  @param item caller
 *  @param url  updatedURL
 */
- (void)previewItem:(PreviewItem*)item updatedURL:(NSURL*)url;

@end
