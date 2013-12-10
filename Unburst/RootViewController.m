//
//  RootViewController.m
//  Unburst
//

@import AssetsLibrary;
@import QuickLook;

#import "RootViewController.h"
#import "ALAssetRepresentation+Unburst.h"
#import "PreviewItem.h"
#import "FooterView.h"

@interface RootViewController () <QLPreviewControllerDataSource, QLPreviewControllerDelegate, PreviewItemDelegate>

@property (strong, nonatomic) IBOutlet UIView *backgroundView;
@property (strong, nonatomic) IBOutlet UILabel *centerLabel;
@property (weak, nonatomic) FooterView *footerView;
@property (strong, nonatomic) QLPreviewController *previewController;

@property (strong, nonatomic) ALAssetsLibrary *assetsLibrary;
@property (strong, nonatomic) ALAssetsGroup *assetsGroup;
@property (strong, nonatomic) NSMutableArray *assets;
@property (strong, nonatomic) NSMutableDictionary *previewItems;

@end

@implementation RootViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.collectionView.backgroundView = self.backgroundView;
    
    ALAuthorizationStatus status = [ALAssetsLibrary authorizationStatus];
    switch (status) {
        case ALAuthorizationStatusRestricted:
            _centerLabel.text = NSLocalizedString(@"This application is not authorized to access photo data.", @"ALAuthorizationStatusRestricted");
            return;
        case ALAuthorizationStatusDenied:
            _centerLabel.text = NSLocalizedString(@"This application needs enable access to your photos.", @"ALAuthorizationStatusDenied");
            return;
        case ALAuthorizationStatusNotDetermined:
        case ALAuthorizationStatusAuthorized:
            _centerLabel.text = NSLocalizedString(@"No Burst mode Photos", @"No Burst mode Photos");
        default:
            break;
    }
    
    _assetsLibrary = [[ALAssetsLibrary alloc]init];
    
    _assets = [NSMutableArray array];
    _previewItems = [NSMutableDictionary dictionary];

    ALAssetsLibraryGroupsEnumerationResultsBlock enumerationBlock = ^(ALAssetsGroup *group, BOOL *stop) {
        if (group) {
            _assetsGroup = group;
            self.title = [_assetsGroup valueForProperty:ALAssetsGroupPropertyName];
            [_assetsGroup setAssetsFilter:[ALAssetsFilter allPhotos]];
            [self loadAssets];
            *stop = YES;
        }
    };
    ALAssetsLibraryAccessFailureBlock failureBlock = ^(NSError *error) {
        dispatch_async(dispatch_get_main_queue(),^{
            if (error.code == ALAssetsLibraryAccessUserDeniedError) {
                _centerLabel.text = NSLocalizedString(@"Need enable access to your photos.", @"ALAuthorizationStatusDenied");
            } else {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:[error description]
                                                                message:nil
                                                               delegate:nil
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles:nil];
                [alert show];
            }
        });
    };
    [_assetsLibrary enumerateGroupsWithTypes:ALAssetsGroupSavedPhotos usingBlock:enumerationBlock failureBlock:failureBlock];

    [[NSNotificationCenter defaultCenter]addObserver:self
                                            selector:@selector(assetsLibraryDidChanged:)
                                                name:ALAssetsLibraryChangedNotification
                                              object:nil];
}

- (void)triggerRemovePreviewItems;
{
    if (_previewController) {
        PreviewItem *currentItem = _previewController.currentPreviewItem;
        [_previewItems removeAllObjects];
        _previewItems[currentItem.assetURL] = currentItem;
        [_previewController reloadData];
    } else {
        [_previewItems removeAllObjects];
    }
}

- (void)loadAssets
{
    dispatch_async(dispatch_get_main_queue(), ^{
        // Manipulating views requires main thread.
        [_assets removeAllObjects];
        if ([_assetsGroup numberOfAssets]) {
            ALAssetsGroupEnumerationResultsBlock enumerationBlock = ^(ALAsset *asset, NSUInteger index, BOOL *stop) {
                if (asset && [asset.defaultRepresentation unburst_hasBurstInfo]) {
                    [_assets addObject:asset];
                }
            };
            [_assetsGroup enumerateAssetsWithOptions:0 usingBlock:enumerationBlock];
        }
        [self.collectionView reloadData];
        if (_previewController) {
            if (_assets.count) {
                PreviewItem *currentItem = _previewController.currentPreviewItem;
                NSUInteger currentIndex = [_assets indexOfObjectPassingTest:^BOOL(ALAsset *asset, NSUInteger idx, BOOL *stop){
                    if ([asset.defaultRepresentation.url isEqual:currentItem.assetURL]) {
                        *stop = YES;
                        return YES;
                    }
                    return NO;
                }];
                [_previewController reloadData];
                _previewController.currentPreviewItemIndex = currentIndex != NSNotFound ? currentIndex : _assets.count-1;
            } else {
                [self.navigationController popToViewController:self animated:YES];
            }
        }
        _footerView.countOfPhotos = _assets.count;
        _backgroundView.hidden = (_assets.count != 0);
    });
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - ALAssetsLibraryChangedNotification

- (void)assetsLibraryDidChanged:(NSNotification*)note
{
    // If assetsGroup has been updated, reload it.
    NSArray *updatedAssetGroups = note.userInfo[ALAssetLibraryUpdatedAssetGroupsKey];
    if ([updatedAssetGroups containsObject:[_assetsGroup valueForProperty:ALAssetsGroupPropertyURL]]){
        [self loadAssets];
    } else if (note.userInfo[ALAssetLibraryUpdatedAssetsKey]) {
        // If updatedAssets exists, update those previewItems.
        NSSet *updatedAssets = note.userInfo[ALAssetLibraryUpdatedAssetsKey];
        for (NSURL *url in updatedAssets) {
            PreviewItem *previewItem = _previewItems[url];
            [previewItem update];
        }
    }
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return _assets.count;
}

#define kImageViewTag 1 // the image view inside the collection view cell prototype is tagged with "1"

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:CellIdentifier forIndexPath:indexPath];
    
    // load the asset for this cell
    ALAsset *asset = _assets[indexPath.row];
    CGImageRef thumbnailImageRef = [asset thumbnail];
    UIImage *thumbnail = [UIImage imageWithCGImage:thumbnailImageRef];
    
    // apply the image to the cell
    UIImageView *imageView = (UIImageView *)[cell viewWithTag:kImageViewTag];
    imageView.image = thumbnail;

    return cell;
}

#define kFooterLabelTag 1   // the label inside the footer view prototype is tagged with "1"

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath;
{
    _footerView = [collectionView dequeueReusableSupplementaryViewOfKind:kind
                                                     withReuseIdentifier:@"FooterView"
                                                            forIndexPath:indexPath];
    _footerView.countOfPhotos = _assets.count;
    return _footerView;
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    // Use QuickLook
    _previewController = [[QLPreviewController alloc]init];
    _previewController.dataSource = self;
    _previewController.delegate = self;
    _previewController.currentPreviewItemIndex = indexPath.row;
    [[self navigationController]pushViewController:_previewController animated:YES];
}

#pragma mark - QLPreviewControllerDataSource

- (NSInteger) numberOfPreviewItemsInPreviewController: (QLPreviewController *) controller;
{
    return _assets.count;
}

- (id <QLPreviewItem>) previewController: (QLPreviewController *) controller previewItemAtIndex: (NSInteger) index;
{
    ALAsset *asset = _assets[index];
    PreviewItem *item = nil;
    if (asset.defaultRepresentation.url) {
        item = _previewItems[asset.defaultRepresentation.url];
        if (!item) {
            item = [PreviewItem previewItemWithDelegate:self forAsset:asset];
            _previewItems[item.assetURL] = item;
        }
    }
    return item;
}

#pragma mark - QLPreviewControllerDelegate

- (void)previewControllerDidDismiss:(QLPreviewController *)controller
{
    _previewController = nil;
}

#pragma mark - PreviewItemDelegate

- (void)previewItem:(PreviewItem *)item updatedURL:(NSURL *)url;
{
    dispatch_async(dispatch_get_main_queue(), ^{
        PreviewItem *currentItem = _previewController.currentPreviewItem;
        if ([item.assetURL isEqual:currentItem.assetURL]) {
            [_previewController refreshCurrentPreviewItem];
        }
    });
}

@end
