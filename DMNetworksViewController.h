//
//  DMNetworksViewController.h
//
//
//  Created by David Murray on 2013-03-03.
//
//

#import <UIKit/UIKit.h>
#import "DMNetworksManager.h"

@interface DMNetworksViewController : UITableViewController

- (void)scanTapped;
- (void)managerDidBeginScanning;
- (void)managerDidFinishScanning;

@end
