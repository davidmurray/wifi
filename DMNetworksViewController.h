//
//  DMNetworksViewController.h
//
//
//  Created by David Murray on 2013-03-03.
//
//

#import <UIKit/UIKit.h>
#import "DMNetworksManager.h"
#import "DMDetailViewController.h"

#define kDMWiFiPowerStateDidChange @"DMWiFiPowerStateDidChange"

@interface UIProgressHUD : UIView
- (id)initWithFrame:(CGRect)frame;
- (void)done;
- (void)hide;
- (void)setFontSize:(int)arg1;
- (void)setText:(id)arg1;
- (void)showInView:(id)arg1;
@end

@interface DMNetworksViewController : UITableViewController {
    UIProgressHUD   *_hud;
    UIBarButtonItem *_scanButton;
    UISwitch        *_switchView;
    long            _numberOfSections;
}

@end
