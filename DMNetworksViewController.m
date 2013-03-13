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
- (void)enabledSwitchChanged:(UISwitch *)aSwitch;
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
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(powerStateDidChange) name:kDMWiFiPowerStateDidChange object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(linkDidChange) name:kDMWiFiLinkDidChange object:nil];

        if ([[DMNetworksManager sharedInstance] isWiFiEnabled])
            [self scanTapped];

        _airPortSettingsBundle = [NSBundle bundleWithPath:@"/System/Library/PreferenceBundles/AirPortSettings.bundle"];
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
}

- (void)scanTapped
{
    if (_numberOfSections == 2) {
        [[self tableView] beginUpdates];

        _numberOfSections = 1;

        [[self tableView] deleteSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationLeft];
        [[self tableView] endUpdates];
    }

    [[DMNetworksManager sharedInstance] reloadNetworks];
}

- (void)managerDidBeginScanning
{
    _hud = [[UIProgressHUD alloc] initWithFrame:CGRectZero];
    [_hud setText:@"Scanning..."];
    [_hud showInView:[[UIApplication sharedApplication] keyWindow]];
}

- (void)managerDidFinishScanning
{
    if (_numberOfSections == 1) {
        [[self tableView] beginUpdates];

        _numberOfSections = 2;

        [[self tableView] insertSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationRight];
        [[self tableView] endUpdates];
    }

    [_hud hide];
    [_hud release];
}

- (void)enabledSwitchChanged:(UISwitch *)aSwitch
{
    BOOL value = [aSwitch isOn];

    [[DMNetworksManager sharedInstance] setWiFiEnabled:value];

    if (value == YES) {
        [self scanTapped];
    } else {
        if (_numberOfSections == 2) {
            [[self tableView] beginUpdates];

            _numberOfSections = 1;

            [[self tableView] deleteSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationLeft];
            [[self tableView] endUpdates];
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

    [_switchView setOn:wiFiEnabled animated:NO];
    [_scanButton setEnabled:wiFiEnabled];
    [self enabledSwitchChanged:_switchView];

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
            return 2;
        case 1:
            return [[[DMNetworksManager sharedInstance] networks] count];
        default:
            return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
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

                _switchView = [[UISwitch alloc] initWithFrame:CGRectZero];
                [cell setAccessoryView:_switchView];
                [_switchView setOn:[[DMNetworksManager sharedInstance] isWiFiEnabled] animated:NO];
                [_switchView addTarget:self action:@selector(enabledSwitchChanged:) forControlEvents:UIControlEventValueChanged];
                [_switchView release];

                break;
            } else {
                [[cell textLabel] setText:@"Information"];
                [[cell textLabel] setTextColor:[UIColor blackColor]];
                [cell setSelectionStyle:UITableViewCellSelectionStyleBlue];
                [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];

                break;
            }
        }

        case 1: {
            DMNetwork *network = [[[DMNetworksManager sharedInstance] networks] objectAtIndex:[indexPath row]];

            [[cell textLabel] setText:[network SSID]];
            [[cell detailTextLabel] setText:[NSString stringWithFormat:@"%.0f dBm", [network RSSI]]];
            [cell setAccessoryType:UITableViewCellAccessoryDetailDisclosureButton];

            // Display a checkmark icon if we are currently connected to that network.

            if ([network isCurrentNetwork])
                [[cell imageView] setImage:[UIImage imageWithContentsOfFile:[_airPortSettingsBundle pathForResource:@"BlueCheck@2x" ofType:@"png"]]];
            else
                [[cell imageView] setImage:[UIImage imageWithContentsOfFile:[_airPortSettingsBundle pathForResource:@"spacer@2x" ofType:@"png"]]];

            break;
        }
    }

    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    DMNetwork *network = [[[DMNetworksManager sharedInstance] networks] objectAtIndex:[indexPath row]];

    DMDetailViewController *detailViewController = [[DMDetailViewController alloc] initWithStyle:UITableViewStyleGrouped network:network];

    [[self navigationController] pushViewController:detailViewController animated:YES];

    [detailViewController release];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([indexPath section] == 0 && [indexPath row] == 1) {
        DMInformationViewController *informationViewController = [[DMInformationViewController alloc] initWithStyle:UITableViewStyleGrouped];

        [[self navigationController] pushViewController:informationViewController animated:YES];

        [informationViewController release];

        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

@end
