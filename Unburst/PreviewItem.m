//
//  PreviewItem.m
//  Unburst
//

#import <AssetsLibrary/AssetsLibrary.h>
#import <ImageIO/ImageIO.h>
#import "PreviewItem.h"
#import "ALAssetRepresentation+Unburst.h"

@interface PreviewItem ()
/*!
 *  re-declare for atomic setter.
 */
@property (strong) NSURL *previewItemURL;
@property (weak, nonatomic) id<PreviewItemDelegate> delegate;

@end

@implementation PreviewItem

+ (instancetype)previewItemWithDelegate:(id<PreviewItemDelegate>)delegate forAsset:(ALAsset*)asset;
{
    static dispatch_once_t onceToken;
    static dispatch_queue_t serialQueue;
    static NSMapTable *urlToPreviewItem;
    
    dispatch_once(&onceToken, ^{
        serialQueue = dispatch_queue_create("_urlToPreviewItem", DISPATCH_QUEUE_SERIAL);
        urlToPreviewItem = [NSMapTable strongToWeakObjectsMapTable];
    });
    __block PreviewItem *item;
    dispatch_sync(serialQueue, ^{
        NSURL *url = asset.defaultRepresentation.url;
        item = [urlToPreviewItem objectForKey:url];
        if (!item) {
            item = [[PreviewItem alloc]initWithDelegate:delegate forAsset:asset];
            [urlToPreviewItem setObject:item forKey:item.assetURL];
        }
    });
    return item;
}

- (instancetype)initWithDelegate:(id<PreviewItemDelegate>)delegate forAsset:(ALAsset*)asset;
{
    self = [super init];
    if (self) {
        _delegate = delegate;
        _assetURL = asset.defaultRepresentation.url;
        [self generateUnburstImageWithAsset:asset];
    }
    return self;
}

- (void)update;
{
    __weak typeof(self) weakSelf = self;
    __block ALAssetsLibrary *assetsLibrary = [[ALAssetsLibrary alloc]init];
    ALAssetsLibraryAssetForURLResultBlock resultBlock = ^(ALAsset *asset){
        __strong typeof (weakSelf) strongSelf = weakSelf;
        [strongSelf generateUnburstImageWithAsset:asset];
        assetsLibrary = nil;
    };
    ALAssetsLibraryAccessFailureBlock failureBlock = ^(NSError *error){
        NSLog(@"assetForURL:resultBlock:failureBlock: %@",error);
    };
    [assetsLibrary assetForURL:_assetURL resultBlock:resultBlock failureBlock:failureBlock];
}

/*!
 *  Generate Unbursted Image as [UUID].JPG into NSTemporaryDirectory()
 */
- (void)generateUnburstImageWithAsset:(ALAsset*)asset;
{
    static dispatch_once_t onceToken;
    static dispatch_queue_t concurrentQueue;
    static dispatch_semaphore_t semaphore;
    dispatch_once(&onceToken, ^{
        concurrentQueue = dispatch_queue_create("generateUnburstImageWithAsset", DISPATCH_QUEUE_CONCURRENT);
        // limit max concurrent operation by semaphore
        semaphore = dispatch_semaphore_create(3);
    });
    
    ALAssetRepresentation *representation = asset.defaultRepresentation;
    NSString *uti = representation.UTI;
    CGImageRef fullResolutionImage = CGImageRetain(representation.fullResolutionImage);
    NSDictionary *unburstedMetadata = representation.unburst_getUnburstedMetadata;
    
    dispatch_async(concurrentQueue, ^{
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        
        NSArray *tempComponents = @[NSTemporaryDirectory(), [[[NSUUID UUID]UUIDString]stringByAppendingPathExtension:@"JPG"]];
        NSURL *tempURL = [NSURL fileURLWithPathComponents:tempComponents];
        CGImageDestinationRef dest = CGImageDestinationCreateWithURL((__bridge CFURLRef)tempURL, (__bridge CFStringRef)(uti), 1, NULL);
        // Check metadata contains AdjustmentXMP
        static NSString *kAdjustmentXMP = @"AdjustmentXMP";
        NSString *XMPString = unburstedMetadata[kAdjustmentXMP];
        if (XMPString) {
            CIImage *image = [CIImage imageWithCGImage:fullResolutionImage];
            NSData *XMP = [XMPString dataUsingEncoding:NSUTF8StringEncoding];
            NSError *error = nil;
            NSArray *filters = [CIFilter filterArrayFromSerializedXMP:XMP inputImageExtent:image.extent error:&error];
            if (error) {
                NSLog(@"CIFilter filterArrayFromSerializedXMP:inputImageExtent:error: %@",error);
            }
            for (CIFilter *filter in filters) {
                [filter setValue:image forKey:kCIInputImageKey];
                image = filter.outputImage;
            }
            CIContext *context = [CIContext contextWithOptions:nil];
            CGImageRef filteredImage = [context createCGImage:image fromRect:image.extent];
            NSMutableDictionary *metadata = [unburstedMetadata mutableCopy];
            [metadata removeObjectForKey:kAdjustmentXMP];
            
            CGImageDestinationAddImage(dest, filteredImage, (__bridge CFDictionaryRef)(metadata));
            
            CFRelease(filteredImage);
        } else {
            CGImageDestinationAddImage(dest, fullResolutionImage, (__bridge CFDictionaryRef)(unburstedMetadata));
        }
        CGImageDestinationFinalize(dest);
        CFRelease(dest);
        CGImageRelease(fullResolutionImage);
        
        dispatch_semaphore_signal(semaphore);
        
        self.previewItemURL = tempURL;
        [_delegate previewItem:self updatedURL:self.previewItemURL];
    });
}

/*!
 *  Discard Unbursted Image.
 */
- (void)discardUnburstImage;
{
    NSError *error = nil;
    if (![[NSFileManager defaultManager]removeItemAtURL:_previewItemURL error:&error]) {
        NSLog(@"Error: %@", error);
    }
    self.previewItemURL = nil;
}

- (void)dealloc
{
    [self discardUnburstImage];
}

@end
