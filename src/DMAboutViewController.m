//
//  DMAboutViewController.m
//
//
//  Created by David Murray on 2014-01-29.
//
//

#import "DMAboutViewController.h"
#import "DMConstants.h"

@interface DMAboutViewController ()

- (void)_doneButtonWasTapped;

@end

@implementation DMAboutViewController

- (void)dealloc
{
	[super dealloc];
}

- (void)viewDidLoad
{
	[super viewDidLoad];

	UIBarButtonItem *doneBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(_doneButtonWasTapped)];
	[[self navigationItem] setRightBarButtonItem:doneBarButtonItem];
	[doneBarButtonItem release];

	[self setTitle:@"About"];
}

- (void)_doneButtonWasTapped
{
	//NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
	//[formatter setNumberStyle:NSNumberFormatterDecimalStyle];
	//NSNumber *interval = [formatter numberFromString:[_intervalTextField text]];
	//[formatter release];

	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setInteger:[[_intervalTextField text] integerValue] forKey:kDMAutoScanIntervalKey];
	[defaults synchronize];

	[self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	// Return the number of sections.
	return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	// Return the number of rows in the section.
	switch (section) {
			case 0:
				return 1;
			case 1:
				return 0;
			default:
				return 0;
	}
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *cellIdentifier = @"Cell";

	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];

	if (cell == nil) {
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellIdentifier] autorelease];
		[cell setSelectionStyle:UITableViewCellSelectionStyleNone];

		switch ([indexPath section]) {
			case 0: {
				[[cell textLabel] setText:@"Auto-Scan Refresh Interval"];

				NSInteger interval = [[NSUserDefaults standardUserDefaults] integerForKey:kDMAutoScanIntervalKey];

				CGRect cellFrame = [cell frame];

				_intervalTextField = [[UITextField alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 80.0f, cellFrame.size.height)];

				[_intervalTextField setTextAlignment:NSTextAlignmentRight];
				[_intervalTextField setKeyboardType:UIKeyboardTypeNumberPad];
				[_intervalTextField setPlaceholder:@"8"];

				if (interval != 0)
					[_intervalTextField setText:[NSString stringWithFormat:@"%ld", (long)interval]];

				[cell setAccessoryView:_intervalTextField];
				[_intervalTextField release];

				break;
			}
		}
	}

	return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	switch (section) {
		case 0:
			return @"Settings";
		case 1:
			return @"About";
		default:
			return nil;
	}
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
	switch (section) {
		case 0:
			return nil;
		case 1:
			return @"Application created by David Murray (Cykey) \u00A9 2013-2014.\nIcon created by Anaxsys.";
		default:
			return nil;
	}
}

@end
