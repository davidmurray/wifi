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

void receivedNotification(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo);

@end

@implementation DMNetworksViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];

    if (self) {

        _numberOfSections = 1;

        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, receivedNotification, CFSTR("com.apple.wifi.powerstatedidchange"), NULL, CFNotificationSuspensionBehaviorCoalesce);

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(managerDidBeginScanning) name:kDMNetworksManagerDidStartScanning object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(managerDidFinishScanning) name:kDMNetworksManagerDidFinishScanning object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(powerStateDidChange) name:kDMWiFiPowerStateDidChange object:nil];

        if ([[DMNetworksManager sharedInstance] isWiFiEnabled])
            [self scanTapped];
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
    CFNotificationCenterRemoveObserver(CFNotificationCenterGetDarwinNotifyCenter(), receivedNotification, NULL, NULL);

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
            return 1;
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
            [[cell textLabel] setText:@"WiFi"];

            _switchView = [[UISwitch alloc] initWithFrame:CGRectZero];
            [cell setAccessoryView:_switchView];
            [_switchView setOn:[[DMNetworksManager sharedInstance] isWiFiEnabled] animated:NO];
            [_switchView addTarget:self action:@selector(enabledSwitchChanged:) forControlEvents:UIControlEventValueChanged];
            [_switchView release];

            break;
        }

        case 1: {
            DMNetwork *network = [[[DMNetworksManager sharedInstance] networks] objectAtIndex:[indexPath row]];

            [[cell textLabel] setText:[network SSID]];
            [[cell detailTextLabel] setText:[NSString stringWithFormat:@"%.0f dBm", [network RSSI]]];

            // Display the text in blue if we are currently connected to that network.
            // Temporary.
            if ([network isCurrentNetwork])
                [[cell textLabel] setTextColor:[UIColor redColor]];

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

#pragma mark - C Functions

void receivedNotification(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kDMWiFiPowerStateDidChange object:nil];
}

@end
