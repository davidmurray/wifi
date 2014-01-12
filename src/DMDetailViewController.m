//
//  DMDetailViewController.m
//
//
//  Created by David Murray on 2013-03-03.
//
//

#import "DMDetailViewController.h"
#import "DMNetworksManager.h"

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
	return ([_network isCurrentNetwork] ? 3 : 2);
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	// Return the number of rows in the section.
	switch (section) {
		case 0:
			return ([_network isCurrentNetwork] ? 1 : 9);
		case 1:
			return ([_network isCurrentNetwork] ? 9 : [[_networkRecord allKeys] count]);
		case 2:
			return ([_network isCurrentNetwork] ? [[_networkRecord allKeys] count] : 0);
		default:
			return 0;
	}
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *disconnectCellIndetifier = @"DisconnectCell";
	static NSString *informationCellIdentifier = @"InformationCell";

	UITableViewCell *cell = nil;

	switch ([indexPath section]) {
		case 0: {
			if ([_network isCurrentNetwork]) {
				NSLog(@"YES OKAY ERALLY IS CURRENT NET");
				cell = [tableView dequeueReusableCellWithIdentifier:disconnectCellIndetifier];

				if (cell == nil) {
					cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:disconnectCellIndetifier] autorelease];
					[[cell textLabel] setTextAlignment:NSTextAlignmentCenter];
				}

				[[cell textLabel] setText:@"Disconnect"];
				break;

			} else {
				NSLog(@"Ynot curent net");

				cell = [tableView dequeueReusableCellWithIdentifier:informationCellIdentifier];

				if (cell == nil) {
					cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:informationCellIdentifier] autorelease];
					[cell setSelectionStyle:UITableViewCellSelectionStyleNone];
				}

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
						[[cell detailTextLabel] setText:[NSString stringWithFormat:@"%@", ([_network isAppleHotspot] ? @"Yes" : @"No")]];
						break;
					} case 4: {
						[[cell textLabel] setText:@"Mac Address"];
						[[cell detailTextLabel] setText:[_network BSSID]];
						break;
					} case 5: {
						[[cell textLabel] setText:@"Ad Hoc"];
						[[cell detailTextLabel] setText:[NSString stringWithFormat:@"%@", ([_network isAdHoc] ? @"Yes" : @"No")]];
						break;
					} case 6: {
						[[cell textLabel] setText:@"Hidden"];
						[[cell detailTextLabel] setText:[NSString stringWithFormat:@"%@", ([_network isHidden] ? @"Yes" : @"No")]];
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
			}
		} case 1: {
			if ([_network isCurrentNetwork]) {
				cell = [tableView dequeueReusableCellWithIdentifier:informationCellIdentifier];

				if (cell == nil) {
					cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:informationCellIdentifier] autorelease];
					[cell setSelectionStyle:UITableViewCellSelectionStyleNone];
				}

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
						[[cell detailTextLabel] setText:[NSString stringWithFormat:@"%@", ([_network isAppleHotspot] ? @"Yes" : @"No")]];
						break;
					} case 4: {
						[[cell textLabel] setText:@"Mac Address"];
						[[cell detailTextLabel] setText:[_network BSSID]];
						break;
					} case 5: {
						[[cell textLabel] setText:@"Ad Hoc"];
						[[cell detailTextLabel] setText:[NSString stringWithFormat:@"%@", ([_network isAdHoc] ? @"Yes" : @"No")]];
						break;
					} case 6: {
						[[cell textLabel] setText:@"Hidden"];
						[[cell detailTextLabel] setText:[NSString stringWithFormat:@"%@", ([_network isHidden] ? @"Yes" : @"No")]];
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
			} else {
				cell = [tableView dequeueReusableCellWithIdentifier:informationCellIdentifier];

				if (cell == nil) {
					cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:informationCellIdentifier] autorelease];
					[cell setSelectionStyle:UITableViewCellSelectionStyleNone];
				}

				// XXX: Consider caching this.
				NSArray *keys = [_networkRecord allKeys];
				NSString *key = [keys objectAtIndex:[indexPath row]];
				[[cell textLabel] setText:key];
				[[cell detailTextLabel] setText:[NSString stringWithFormat:@"%@", [_networkRecord objectForKey:key]]];
				break;
			}
		} case 2: {
			cell = [tableView dequeueReusableCellWithIdentifier:informationCellIdentifier];

			if (cell == nil) {
				cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:informationCellIdentifier] autorelease];
				[cell setSelectionStyle:UITableViewCellSelectionStyleNone];
			}

			// XXX: Consider caching this.
			NSArray *keys = [_networkRecord allKeys];
			NSString *key = [keys objectAtIndex:[indexPath row]];
			[[cell textLabel] setText:key];
			[[cell detailTextLabel] setText:[NSString stringWithFormat:@"%@", [_networkRecord objectForKey:key]]];
		}
	}

	return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	return (section == 1 ? @"Record" : nil);
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if ([indexPath section] == 0 && [_network isCurrentNetwork]) {
		[[DMNetworksManager sharedInstance] disassociate];

		[tableView deselectRowAtIndexPath:indexPath animated:YES];
	}
}

@end
