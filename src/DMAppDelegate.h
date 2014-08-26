#import "DMNetworksViewController.h"

@interface DMAppDelegate : UIApplication <UIApplicationDelegate> {
	UIWindow                 *_window;
	UINavigationController   *_navigationController;
	DMNetworksViewController *_networksViewController;
}

@property (nonatomic, retain) UIWindow *window;

@end