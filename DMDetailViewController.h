//
//  DMDetailViewController.h
//
//
//  Created by David Murray on 2013-03-03.
//
//

#import <UIKit/UIKit.h>
#import "DMNetwork.h"

@interface DMDetailViewController : UITableViewController {
	DMNetwork    *_network;
	NSDictionary *_networkRecord;
}

- (id)initWithStyle:(UITableViewStyle)style network:(DMNetwork *)network;

@end
