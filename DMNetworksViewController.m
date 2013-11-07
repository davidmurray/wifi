//
//  DMNetworksViewController.m
//
//
//  Created by David Murray on 2013-03-03.
//
//

#import "DMNetworksViewController.h"

@interface DMNetworksViewController ()

- (void)scanTapped;
- (void)managerDidBeginScanning;
- (void)managerDidFinishScanning;
- (void)managerDidBeginAssociating;
- (void)managerDidFinishAssociating;
- (void)switchValueChanged:(UISwitch *)aSwitch;
- (void)powerStateDidChange;
- (void)linkDidChange;

@end

@implementation DMNetworksViewController

- (id)initWithStyle:(UITableViewStyle)style
{
	self = [super initWithStyle:style];

	if (self) {

		_numberOfSections = 1;

		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(managerDidBeginScanning) name:kDMNetworksManagerDidStartScanning object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(managerDidFinishScanning) name:kDMNetworksManagerDidFinishScanning object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(managerDidBeginAssociating) name:kDMNetworksManagerDidStartAssociating object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(managerDidFinishAssociating) name:kDMNetworksManagerDidFinishAssociating object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(powerStateDidChange) name:kDMWiFiPowerStateDidChange object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(linkDidChange) name:kDMWiFiLinkDidChange object:nil];

		if ([[DMNetworksManager sharedInstance] isWiFiEnabled])
			[self scanTapped];

		// I know, this is bad.
		_airPortSettingsBundle = [[NSBundle bundleWithPath:@"/System/Library/PreferenceBundles/AirPortSettings.bundle"] retain];

		// Set up a timer to automatically initiate a scan every 8 seconds.
		if ([[NSUserDefaults standardUserDefaults] boolForKey:kDMAutoScanKey])
			_autoScanTimer = [NSTimer scheduledTimerWithTimeInterval:8 target:self selector:@selector(scanTapped) userInfo:nil repeats:YES];
	}

	return self;
}

- (void)viewDidLoad
{
	[super viewDidLoad];

	_scanButton = [[UIBarButtonItem alloc] initWithTitle:@"Scan" style:UIBarButtonItemStyleBordered target:self action:@selector(scanTapped)];
	[_scanButton setEnabled:[[DMNetworksManager sharedInstance] isWiFiEnabled]];
	[[self navigationItem] setLeftBarButtonItem:_scanButton];
	[_scanButton release];

	[self setTitle:@"Networks"];
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];

	[super dealloc];
	[_airPortSettingsBundle release];
}

- (void)scanTapped
{
	// Don't initiate a scan if WiFi is off.
	if ([[DMNetworksManager sharedInstance] isWiFiEnabled] == NO)
		return;

	if (_numberOfSections == 2) {
		[[self tableView] beginUpdates];

		_numberOfSections = 1;

		[[self tableView] deleteSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationAutomatic];
		[[self tableView] endUpdates];
	}

	[[DMNetworksManager sharedInstance] reloadNetworks];
}

- (void)managerDidBeginScanning
{
	_hud = [[UIProgressHUD alloc] initWithFrame:CGRectZero];
	[_hud setText:@"Scanning..."];
	[_hud showInView:[[UIApplication sharedApplication] keyWindow]];

	// Prevent scrolling the tableview when there's an HUD.
	[[self tableView] setScrollEnabled:NO];
}

- (void)managerDidFinishScanning
{
	[[self tableView] setScrollEnabled:YES];

	if (_numberOfSections == 1) {
		[[self tableView] beginUpdates];

		_numberOfSections = 2;

		[[self tableView] insertSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationAutomatic];
		[[self tableView] endUpdates];
	}

	[_hud hide];
	[_hud release];

	// Display the number of networks in the navigation bar.
	[self setTitle:[NSString stringWithFormat:@"Networks (%u)", [[[DMNetworksManager sharedInstance] networks] count]]];
}

- (void)managerDidBeginAssociating
{
	[[self tableView] reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationNone];
}

- (void)managerDidFinishAssociating
{
	[[self tableView] reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationNone];
}

- (void)switchValueChanged:(UISwitch *)aSwitch
{
	BOOL value = [aSwitch isOn];

	if ([aSwitch tag] == kDMWiFiEnabledSwitchTag) {
		[[DMNetworksManager sharedInstance] setWiFiEnabled:value];

		if (value == YES) {
			[self scanTapped];
		} else {
			if (_numberOfSections == 2) {
				[[self tableView] beginUpdates];

				_numberOfSections = 1;

				[[self tableView] deleteSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationAutomatic];
				[[self tableView] endUpdates];
			}

			[self setTitle:@"Networks"];
		}
	} else {
		// Save the value.
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		[defaults setBool:value forKey:kDMAutoScanKey];
		[defaults synchronize];

		// Stop the timer if the switch was set to NO or start it if was set to YES.
		if (value == NO) {
			[_autoScanTimer invalidate];
			_autoScanTimer = nil;
		} else {
			_autoScanTimer = [NSTimer scheduledTimerWithTimeInterval:8 target:self selector:@selector(scanTapped) userInfo:nil repeats:YES];
		}
	}
}

- (void)linkDidChange
{
	NSLog(@"link did change");
}

- (void)powerStateDidChange
{
	BOOL wiFiEnabled = [[DMNetworksManager sharedInstance] isWiFiEnabled];

	[_enabledSwitchView setOn:wiFiEnabled animated:NO];
	[_scanButton setEnabled:wiFiEnabled];
	[self switchValueChanged:_enabledSwitchView];

	if (wiFiEnabled)
		[[DMNetworksManager sharedInstance] reloadNetworks];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return _numberOfSections;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	// Return the number of rows in the section.

	switch (section) {
		case 0:
			return 3;
		case 1:
			return [[[DMNetworksManager sharedInstance] networks] count];
		default:
			return 0;
	}
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *CellIdentifier = @"WiFiCellIdentifier";
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];

	if (cell == nil) {
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
		[cell setSelectionStyle:UITableViewCellSelectionStyleNone];
		[cell setAccessoryType:UITableViewCellAccessoryDetailDisclosureButton];
	}

	switch ([indexPath section]) {
		case 0: {
			if ([indexPath row] == 0) {
				[[cell textLabel] setText:@"WiFi"];
				[[cell textLabel] setTextColor:[UIColor blackColor]];
				[[cell detailTextLabel] setText:nil];
				[[cell imageView] setImage:nil];

				_enabledSwitchView = [[UISwitch alloc] init];
				[_enabledSwitchView setTag:kDMWiFiEnabledSwitchTag];
				[_enabledSwitchView setOn:[[DMNetworksManager sharedInstance] isWiFiEnabled] animated:NO];
				[_enabledSwitchView addTarget:self action:@selector(switchValueChanged:) forControlEvents:UIControlEventValueChanged];
				[cell setSelectionStyle:UITableViewCellSelectionStyleNone];
				[cell setAccessoryView:_enabledSwitchView];
				[_enabledSwitchView release];

				break;
			} else if ([indexPath row] == 1) {
				[[cell textLabel] setText:@"Auto-Scan"];
				[[cell textLabel] setTextColor:[UIColor blackColor]];
				[[cell detailTextLabel] setText:nil];
				[[cell imageView] setImage:nil];
				[cell setSelectionStyle:UITableViewCellSelectionStyleNone];

				UISwitch *switchView = [[UISwitch alloc] init];
				[switchView setTag:kDMAutoScanEnabledSwitchTag];
				[switchView setOn:[[NSUserDefaults standardUserDefaults] boolForKey:kDMAutoScanKey] animated:NO];
				[switchView addTarget:self action:@selector(switchValueChanged:) forControlEvents:UIControlEventValueChanged];

				[cell setAccessoryView:switchView];
				[switchView release];

				break;
			} else if ([indexPath row] == 2) {
				[[cell textLabel] setText:@"Information"];
				[[cell textLabel] setTextColor:[UIColor blackColor]];
				[[cell detailTextLabel] setText:nil];
				[[cell imageView] setImage:nil];
				[cell setSelectionStyle:UITableViewCellSelectionStyleBlue];
				[cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
				[cell setAccessoryView:nil];

				break;
			}
		}

		case 1: {
			DMNetwork *network = [[[DMNetworksManager sharedInstance] networks] objectAtIndex:[indexPath row]];

			[[cell textLabel] setText:[network SSID]];
			[[cell detailTextLabel] setText:[NSString stringWithFormat:@"%.0f dBm", [network RSSI]]];
			[cell setSelectionStyle:UITableViewCellSelectionStyleBlue];
			[cell setAccessoryType:UITableViewCellAccessoryDetailDisclosureButton];
			[cell setAccessoryView:nil];

			// Display a blue checkmark icon if we are currently connected to that network.
			if ([network isCurrentNetwork]) {
				[[cell imageView] setImage:[UIImage imageWithContentsOfFile:[_airPortSettingsBundle pathForResource:@"BlueCheck@2x" ofType:@"png"]]];
				[[cell textLabel] setTextColor:[UIColor tableCellValue1BlueColor]];
				if (_spinner)
					[_spinner removeFromSuperview];
			} else {
				[[cell imageView] setImage:[UIImage imageWithContentsOfFile:[_airPortSettingsBundle pathForResource:@"spacer@2x" ofType:@"png"]]];
				[[cell textLabel] setTextColor:[UIColor blackColor]];
				if ([network isAssociating]) {
					_spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
					[[cell imageView] addSubview:_spinner];
					[_spinner startAnimating];
					[_spinner release];
					_spinner = nil;
				}
			}

			break;
		}
	}

	return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
	DMNetwork *network = [[[DMNetworksManager sharedInstance] networks] objectAtIndex:[indexPath row]];

	DMDetailViewController *detailViewController = [[DMDetailViewController alloc] initWithStyle:UITableViewStyleGrouped network:network];

	[[self navigationController] pushViewController:detailViewController animated:YES];

	[detailViewController release];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if ([indexPath section] == 0 && [indexPath row] == 2) {
		DMInformationViewController *informationViewController = [[DMInformationViewController alloc] initWithStyle:UITableViewStyleGrouped];

		[[self navigationController] pushViewController:informationViewController animated:YES];

		[informationViewController release];

	} else if ([indexPath section] == 1) {
		DMNetworksManager *manager = [DMNetworksManager sharedInstance];

		DMNetwork *network = [[manager networks] objectAtIndex:[indexPath row]];

		if ([network requiresUsername] == NO && [network requiresPassword] == NO) {
			[manager associateWithNetwork:network];
		} else {
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"\"%@\" requires authentication.", [network SSID]] message:nil delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Connect", nil];
			[alert setAlertViewStyle:([network requiresUsername] == YES ? UIAlertViewStyleLoginAndPasswordInput : UIAlertViewStyleSecureTextInput)];
			[alert show];
			[alert release];

			_associatingNetwork = network;
		}
	}

	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if (buttonIndex == 1) {
		if ([_associatingNetwork requiresUsername]) {
			[_associatingNetwork setUsername:[[alertView textFieldAtIndex:0] text]];
			[_associatingNetwork setPassword:[[alertView textFieldAtIndex:1] text]];
		} else {
			[_associatingNetwork setPassword:[[alertView textFieldAtIndex:0] text]];
		}

		[[DMNetworksManager sharedInstance] associateWithNetwork:_associatingNetwork];

		_associatingNetwork = nil;
	}
}

@end
