#import "DMNetworksViewController.h"

@interface WiFiApplication : UIApplication <UIApplicationDelegate> {
	UIWindow                 *_window;
	UINavigationController   *_navigationController;
	DMNetworksViewController *_networksViewController;
}
@property (nonatomic, retain) UIWindow *window;

@end

@implementation WiFiApplication
@synthesize window = _window;

- (void)applicationDidFinishLaunching:(UIApplication *)application
{
	_window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

	_networksViewController = [[DMNetworksViewController alloc] initWithStyle:UITableViewStyleGrouped];
	_navigationController = [[UINavigationController alloc] initWithRootViewController:_networksViewController];

	[_window setRootViewController:_navigationController];
	[_window makeKeyAndVisible];
}

- (void)dealloc
{
	[_networksViewController release];
	[_navigationController release];
	[_window release];

	[super dealloc];
}

@end
