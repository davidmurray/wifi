//
//  DMDetailViewController.m
//
//
//  Created by David Murray on 2013-03-03.
//
//

#import "DMDetailViewController.h"

@interface DMDetailViewController ()

@end

@implementation DMDetailViewController

- (id)initWithStyle:(UITableViewStyle)style network:(DMNetwork *)network
{
	self = [super initWithStyle:style];

	if (self) {
		_network = [network retain];

		_networkRecord = [[network record] copy];
	}

	return self;
}

- (void)dealloc
{
	[_network release];
	[_networkRecord release];

	[super dealloc];
}

- (void)viewDidLoad
{
	[super viewDidLoad];

	[self setTitle:[_network SSID]];
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
	return (section == 0 ? 9 : [[_networkRecord allKeys] count]);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *CellIdentifier = @"Cell";
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];

	if (cell == nil) {
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier] autorelease];
		[cell setSelectionStyle:UITableViewCellEditingStyleNone];
	}

	switch ([indexPath section]) {

		case 0: {
			switch ([indexPath row]) {
				case 0: {
					[[cell textLabel] setText:@"Encryption Model"];
					[[cell detailTextLabel] setText:[_network encryptionModel]];
					break;
				} case 1: {
					[[cell textLabel] setText:@"Channel"];
					[[cell detailTextLabel] setText:[NSString stringWithFormat:@"%i", [_network channel]]];
					break;
				} case 2: {
					[[cell textLabel] setText:@"Bars"];
					[[cell detailTextLabel] setText:[NSString stringWithFormat:@"%i", [_network bars]]];
					break;
				} case 3: {
					[[cell textLabel] setText:@"Apple Personal Hotspot"];
					[[cell detailTextLabel] setText:[NSString stringWithFormat:@"%@", ([_network isAppleHotspot] == YES ? @"Yes" : @"No")]];
					break;
				} case 4: {
					[[cell textLabel] setText:@"Mac Address"];
					[[cell detailTextLabel] setText:[_network BSSID]];
					break;
				} case 5: {
					[[cell textLabel] setText:@"Ad Hoc"];
					[[cell detailTextLabel] setText:[NSString stringWithFormat:@"%@", ([_network isAdHoc] == YES ? @"Yes" : @"No")]];
					break;
				} case 6: {
					[[cell textLabel] setText:@"Hidden"];
					[[cell detailTextLabel] setText:[NSString stringWithFormat:@"%@", ([_network isHidden] == YES ? @"Yes" : @"No")]];
					break;
				} case 7: {
					[[cell textLabel] setText:@"AP Mode"];
					[[cell detailTextLabel] setText:[NSString stringWithFormat:@"%i", [_network APMode]]];
					break;
				} case 8: {
					[[cell textLabel] setText:@"Vendor"];
					[[cell detailTextLabel] setText:[_network vendor]];
					break;
				}
			}

			break;
		} case 1: {

			// XXX: Consider caching this.
			NSArray *keys = [_networkRecord allKeys];
			NSString *key = [keys objectAtIndex:[indexPath row]];
			[[cell textLabel] setText:key];
			[[cell detailTextLabel] setText:[NSString stringWithFormat:@"%@", [_networkRecord objectForKey:key]]];

			break;
		}
	}

	return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	return (section == 1 ? @"Record" : nil);
}

@end
