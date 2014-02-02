//
//  DMInformationViewController.m
//
//  Created by David Murray on 2013-03-05.
//

#import "DMInformationViewController.h"
#import "DMNetworksManager.h"

@interface DMInformationViewController ()

- (void)_reloadKnownNetworks;

@end

@implementation DMInformationViewController

- (void)viewDidLoad
{
	[super viewDidLoad];

	[self setTitle:@"Information"];
	[[self navigationItem] setRightBarButtonItem:[self editButtonItem]];

	[self _reloadKnownNetworks];
}

- (void)dealloc
{
	[_knownNetworks release];

	[super dealloc];
}

- (void)_reloadKnownNetworks
{
	if (_knownNetworks) {
		[_knownNetworks release];
		_knownNetworks = nil;
	}

	_knownNetworks = [[[DMNetworksManager sharedInstance] knownNetworks] copy];
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
			return [[[DMNetworksManager sharedInstance] knownNetworks] count];
		default:
			return 0;
	}
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	switch (section) {
		case 0:
			return @"General";
		case 1:
			return @"Known Networks";
		default:
			return nil;
	}
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *generalIdentifier = @"GeneralCell";
	static NSString *knownNetworksIdentifier = @"KnownNetworksCell";

	NSInteger section = [indexPath section];

	NSString *identifier = (section > 0 ? knownNetworksIdentifier : generalIdentifier);

	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];

	if (cell == nil) {
		cell = [[[UITableViewCell alloc] initWithStyle:(section > 0 ? UITableViewCellStyleSubtitle : UITableViewCellStyleValue1) reuseIdentifier:identifier] autorelease];
		[cell setSelectionStyle:UITableViewCellSelectionStyleNone];
	}

	switch (section) {
		case 0: {
			[[cell textLabel] setText:@"Interface"];
			[[cell detailTextLabel] setText:[[DMNetworksManager sharedInstance] interfaceName]];
			break;
		}
		case 1: {
			WiFiNetworkRef network = (WiFiNetworkRef)[_knownNetworks objectAtIndex:[indexPath row]];
			[[cell textLabel] setText:(NSString *)WiFiNetworkGetSSID(network)];
			[[cell detailTextLabel] setText:(NSString *)WiFiNetworkGetProperty(network, CFSTR("BSSID"))];
			break;
		}
	}

	return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
	return ([indexPath section]);
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
		WiFiNetworkRef network = (WiFiNetworkRef)[_knownNetworks objectAtIndex:[indexPath row]];
    	[[DMNetworksManager sharedInstance] removeNetwork:network];
    	[self _reloadKnownNetworks];
    	[tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
}

#pragma mark - UITableViewDelegate

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return UITableViewCellEditingStyleDelete;
}

- (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath
{
	return NO;
}

@end
