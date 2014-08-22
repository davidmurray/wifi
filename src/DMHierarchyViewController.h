//
//  DMHierarchyViewController.h
//
//
//  Created by David Murray on 2/8/2014.
//
//

#import <UIKit/UIKit.h>

BOOL DMHierarchyViewControllerDataRequiresFullViewController(id data);
NSString *DMHierarchyViewControllerFormattedSmallData(id data);
void DMHierarchyViewControllerGetCellTitleAndDetailAndValue(id data, NSString *dataTitle, NSIndexPath *indexPath, NSString **title, NSString **detail, id *value);

@interface DMHierarchyViewController : UITableViewController {
	id _data;
	NSString *_dataTitle;
}

- (id)initWithStyle:(UITableViewStyle)style backingData:(id)data dataTitle:(NSString *)dataTitle;

@end
