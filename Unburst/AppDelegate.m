//
//  AppDelegate.m
//  Unburst
//

#import "AppDelegate.h"
#import "RootViewController.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Remove all JPG files in NSTemporaryDirectory()
    NSError *error;
    NSArray *temporaryFiles = [[NSFileManager defaultManager]contentsOfDirectoryAtPath:NSTemporaryDirectory() error:&error];
    if (error) {
        NSLog(@"contentsOfDirectoryAtPath: error:%@",error);
    }
    if (temporaryFiles.count) {
        [temporaryFiles enumerateObjectsWithOptions:NSEnumerationConcurrent
                                         usingBlock:^(NSString *path, NSUInteger idx, BOOL *stop){
            if ([path hasSuffix:@".JPG"]) {
                NSError *error;
                [[NSFileManager defaultManager]removeItemAtPath:[NSString pathWithComponents:@[NSTemporaryDirectory(),path]]
                                                          error:&error];
                if (error) {
                    NSLog(@"removeItemAtPath: %@ error: %@", path, error);
                }
            }
        }];
    }
    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Remove JPG files in NSTemporaryDirectory() except previewing one.
    UINavigationController *nav = (UINavigationController *)self.window.rootViewController;
    RootViewController *rootViewController = nav.viewControllers[0];
    [rootViewController triggerRemovePreviewItems];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
