//
//  DMNetworksViewController.m
//
//
//  Created by David Murray on 2013-03-03.
//
//

#import "DMNetworksViewController.h"
#import "DMNetworksManager.h"
#import "DMDetailViewController.h"
#import "DMInformationViewController.h"
#import "DMAboutViewController.h"

@interface DMNetworksViewController ()

- (void)scanButtonWasTapped;
- (void)infoButtonWasTapped;
- (void)_initiateScan;
- (void)_startAutoScanTimerIfNecessary;
- (void)managerDidBeginScanning;
- (void)managerDidFinishScanning;
- (void)managerDidBeginAssociating;
- (void)managerDidFinishAssociating;
- (void)switchValueChanged:(UISwitch *)aSwitch;
- (void)powerStateDidChange;
- (void)linkDidChange;
- (void)scanDidFail:(NSNotification *)notification;
- (void)associationDidFail:(NSNotification *)notification;
- (void)managerDidDisassociate;

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
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(scanDidFail:) name:kDMNetworksManagerScanningDidFail object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(associationDidFail:) name:kDMNetworksManagerAssociatingDidFail object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(managerDidDisassociate) name:kDMNetworksManagerDidDisassociate object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userDefaultsDidChange) name:NSUserDefaultsDidChangeNotification object:nil];


		// Initially start a scan.
		[self _initiateScan];

		// I know, this is bad.
		_airPortSettingsBundle = [[NSBundle bundleWithPath:@"/System/Library/PreferenceBundles/AirPortSettings.bundle"] retain];

		// Set up a timer to automatically initiate a scan at a specified interval.
		[self _startAutoScanTimerIfNecessary];
	}

	return self;
}

- (void)viewDidLoad
{
	[super viewDidLoad];

	_scanButton = [[UIBarButtonItem alloc] initWithTitle:@"Scan" style:UIBarButtonItemStyleBordered target:self action:@selector(scanButtonWasTapped)];
	[_scanButton setEnabled:[[DMNetworksManager sharedInstance] isWiFiEnabled]];
	[[self navigationItem] setLeftBarButtonItem:_scanButton];
	[_scanButton release];

	UIButton *infoButton = [UIButton buttonWithType:UIButtonTypeInfoLight];
	[infoButton addTarget:self action:@selector(infoButtonWasTapped) forControlEvents:UIControlEventTouchUpInside];
	UIBarButtonItem *barButton = [[UIBarButtonItem alloc] initWithCustomView:infoButton];
	[[self navigationItem] setRightBarButtonItem:barButton animated:NO];
	[barButton release];

	[self setTitle:@"Networks"];
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[_airPortSettingsBundle release];
	[_autoScanTimer release];

	[super dealloc];
}

- (void)scanButtonWasTapped
{
	// If the auto-scan timer is running, restart it so that we do not scan twice in a very short interval.
	[self _startAutoScanTimerIfNecessary];

	// Initiate a scan.
	[self _initiateScan];
}

- (void)infoButtonWasTapped
{
	DMAboutViewController *aboutViewController = [[DMAboutViewController alloc] initWithStyle:UITableViewStyleGrouped];
	UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:aboutViewController];

	[self presentViewController:navigationController animated:YES completion:nil];
	[aboutViewController release];
	[navigationController release];
}

- (void)_initiateScan
{
	// Don't initiate a scan if WiFi is off.
	if (![[DMNetworksManager sharedInstance] isWiFiEnabled])
		return;

	if (_numberOfSections == 2) {
		[[self tableView] beginUpdates];

		_numberOfSections = 1;

		[[self tableView] deleteSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationAutomatic];
		[[self tableView] endUpdates];
	}

	[[DMNetworksManager sharedInstance] scan];
}

- (void)_startAutoScanTimerIfNecessary
{
	if (_autoScanTimer) {
		[_autoScanTimer invalidate];
		_autoScanTimer = nil;
	}

	// This auto-scan code should really be refactored.
	if ([[NSUserDefaults standardUserDefaults] boolForKey:kDMAutoScanEnabledKey]) {
		NSInteger interval = [[NSUserDefaults standardUserDefaults] integerForKey:kDMAutoScanIntervalKey];
		if (interval == 0)
			interval = 8;

		_autoScanTimer = [NSTimer scheduledTimerWithTimeInterval:interval target:self selector:@selector(_initiateScan) userInfo:nil repeats:YES];
	}
}

- (void)managerDidBeginScanning
{
	// Only show the HUD if this view controller is currently visible.
	if ([[self navigationController] visibleViewController] == self) {
		_hud = [[UIProgressHUD alloc] initWithFrame:CGRectZero];
		[_hud setText:@"Scanning..."];
		[_hud showInView:[[UIApplication sharedApplication] keyWindow]];
	}

	// Prevent scrolling the tableview when there's an HUD.
	[[self tableView] setScrollEnabled:NO];

	// Show the network activity indicator.
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
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

	if (_hud) {
		[_hud hide];
		[_hud release];
		_hud = nil;
	}

	// Hide the network activity indicator.
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];

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

		if (value) {
			[self _initiateScan];
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
		[defaults setBool:value forKey:kDMAutoScanEnabledKey];
		[defaults synchronize];

		// Stop the timer if the switch was set to NO or start it if was set to YES.
		if (!value) {
			[_autoScanTimer invalidate];
			_autoScanTimer = nil;
		} else {
			[self _startAutoScanTimerIfNecessary];
		}
	}
}

- (void)userDefaultsDidChange
{
	// Restart the auto scan timer.
	[self _startAutoScanTimerIfNecessary];
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
		[self _initiateScan];
}

- (void)scanDidFail:(NSNotification *)notification
{
	int error = [[[notification userInfo] objectForKey:kDMErrorValueKey] intValue];

	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Couldn't scan." message:[NSString stringWithFormat:@"There was an error while scanning: %d", error] delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil];
	[alert show];
	[alert release];

	[[self tableView] reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationNone];
}

- (void)associationDidFail:(NSNotification *)notification
{
	int error = [[[notification userInfo] objectForKey:kDMErrorValueKey] intValue];

	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Couldn't join network" message:[NSString stringWithFormat:@"There was an error while joining this network. \nError: %d", error] delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil];
	[alert show];
	[alert release];

	[[self tableView] reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationNone];
}

- (void)managerDidDisassociate
{
	// gotta fix this
	if (!_associatingNetwork) {
		[self _initiateScan];
	}
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return _numberOfSections;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
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
	static NSString *cellIdentifier = @"WiFiCellIdentifier";
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];

	if (cell == nil) {
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier] autorelease];
		[cell setSelectionStyle:UITableViewCellSelectionStyleNone];

		if (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_7_0)
			[cell setAccessoryType:UITableViewCellAccessoryDetailButton];
		else
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
				[switchView setOn:[[NSUserDefaults standardUserDefaults] boolForKey:kDMAutoScanEnabledKey] animated:NO];
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
		} case 1: {
			DMNetwork *network = [[[DMNetworksManager sharedInstance] networks] objectAtIndex:[indexPath row]];

			[[cell textLabel] setText:[network SSID]];
			[[cell detailTextLabel] setText:[NSString stringWithFormat:@"%.0f dBm", [network RSSI]]];
			[cell setSelectionStyle:UITableViewCellSelectionStyleBlue];
			if (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_7_0)
				[cell setAccessoryType:UITableViewCellAccessoryDetailButton];
			else
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

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	switch (section) {
		case 0:
			return @"General";
		case 1:
			return @"Networks";
		default:
			return nil;
	}
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

		if (![network isCurrentNetwork]) {
			if (![network requiresUsername] && ![network requiresPassword]) {
				[manager associateWithNetwork:network];
			} else {
				UIAlertView *alert = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"\"%@\" requires authentication.", [network SSID]] message:nil delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Connect", nil];
				[alert setAlertViewStyle:([network requiresUsername] ? UIAlertViewStyleLoginAndPasswordInput : UIAlertViewStyleSecureTextInput)];
				[alert show];
				[alert release];

				_associatingNetwork = network;
			}
		}
	}

	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (BOOL)tableView:(UITableView *)tableView shouldShowMenuForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return ([indexPath section] == 1);
}

- (BOOL)tableView:(UITableView *)tableView canPerformAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender
{
	return (action == @selector(copy:));
}

- (void)tableView:(UITableView *)tableView performAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender
{
	DMNetwork *network = [[[DMNetworksManager sharedInstance] networks] objectAtIndex:[indexPath row]];

	NSString *text = [NSString stringWithFormat:@"%@ - %.0f dBm", [network SSID], [network RSSI]];
	[[UIPasteboard generalPasteboard] setString:text];
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
