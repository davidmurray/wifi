//
//  DMNetworksViewController.h
//
//
//  Created by David Murray on 2013-03-03.
//
//

#import <UIKit/UIKit.h>

@class DMNetwork;

// Interface declarations for private APIs.

@interface UIProgressHUD : UIView
- (id)initWithFrame:(CGRect)frame;
- (void)done;
- (void)hide;
- (void)setFontSize:(int)arg1;
- (void)setText:(id)arg1;
- (void)showInView:(id)arg1;
@end

@interface UIImage ()
- (UIImage *)imageNamed:(NSString *)named inBundle:(NSBundle *)bundle;
@end

UIKIT_EXTERN UIImage *_UIImageWithName(NSString *name);

@interface UIColor (Private)
+ (UIColor *)tableCellValue1BlueColor;
@end

@interface DMNetworksViewController : UITableViewController <UIAlertViewDelegate> {
	UIProgressHUD           *_hud;
	UIBarButtonItem         *_scanButton;
	UISwitch                *_enabledSwitchView;
	UIActivityIndicatorView *_spinner;
	NSBundle                *_airPortSettingsBundle;
	NSTimer                 *_autoScanTimer;
	long                    _numberOfSections;
	DMNetwork               *_associatingNetwork;
}

@end
