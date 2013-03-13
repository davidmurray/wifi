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
    }

    return self;
}

- (void)dealloc
{
    [_network release];

    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self setTitle:[_network SSID]];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return 6;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];

    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier] autorelease];
        [cell setSelectionStyle:UITableViewCellEditingStyleNone];
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
            [[cell textLabel] setText:@"Apple Personal Hotspot"];
            [[cell detailTextLabel] setText:[NSString stringWithFormat:@"%@", ([_network isAppleHotspot] == YES ? @"Yes" : @"No")]];
            break;
        } case 3: {
            [[cell textLabel] setText:@"Mac Address"];
            [[cell detailTextLabel] setText:[_network BSSID]];
            break;
        } case 4: {
            [[cell textLabel] setText:@"Ad Hoc"];
            [[cell detailTextLabel] setText:[NSString stringWithFormat:@"%@", ([_network isAdHoc] == YES ? @"Yes" : @"No")]];
            break;
        } case 5: {
            [[cell textLabel] setText:@"Hidden"];
            [[cell detailTextLabel] setText:[NSString stringWithFormat:@"%@", ([_network isHidden] == YES ? @"Yes" : @"No")]];
            break;
        }
    }

    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     */
}

@end
