//
//  DMInformationViewController.m
//
//  Created by David Murray on 2013-03-05.
//

#import "DMInformationViewController.h"

@interface DMInformationViewController ()

@end

@implementation DMInformationViewController

- (void)viewDidLoad
{
	[super viewDidLoad];
	[self setTitle:@"Information"];
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
	return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *CellIdentifier = @"Cell";
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];

	if (cell == nil) {
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier] autorelease];
		[cell setSelectionStyle:UITableViewCellSelectionStyleNone];
	}

	switch ([indexPath row]) {
		case 0: {
			[[cell textLabel] setText:@"Interface"];
			[[cell detailTextLabel] setText:[[DMNetworksManager sharedInstance] interfaceName]];
			break;
		}
	}

	return cell;
}


@end
