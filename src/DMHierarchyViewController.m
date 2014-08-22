//
//  DMHierarchyViewController.m
//
//
//  Created by David Murray on 2/8/2014.
//
//

#import "DMHierarchyViewController.h"

@interface DMHierarchyViewController ()

@end

@implementation DMHierarchyViewController

- (id)initWithStyle:(UITableViewStyle)style backingData:(id)data dataTitle:(NSString *)dataTitle
{
	self = [super initWithStyle:style];

	if (self) {
		_data = [data retain];
		_dataTitle = [dataTitle copy];
	}

	return self;
}

- (void)dealloc
{
	[_data release];
	[_dataTitle release];

	[super dealloc];
}

- (void)viewDidLoad
{
	[super viewDidLoad];

	[[self navigationItem] setTitle:_dataTitle];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if ([_data isKindOfClass:[NSString class]]) {
		return 1;
	} else if ([_data isKindOfClass:[NSNumber class]]) {
		return 1;
	}  else if ([_data isKindOfClass:[NSData class]]) {
		return 1;
	} else if ([_data isKindOfClass:[NSArray class]]) {
		return [_data count];
	} else if ([_data isKindOfClass:[NSDictionary class]]) {
		return [[_data allKeys] count];
	}

	// Should never be reached.
	return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *cellIdentifier = @"Cell";
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];

	if (!cell) {
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellIdentifier] autorelease];
	}

	NSString *title = nil;
	NSString *detail = nil;
	id value = nil;
	DMHierarchyViewControllerGetCellTitleAndDetailAndValue(_data, _dataTitle, indexPath, &title, &detail, &value);

	[[cell textLabel] setText:title];
	[[cell detailTextLabel] setText:detail];

	if (!DMHierarchyViewControllerDataRequiresFullViewController(value)) {
		[cell setAccessoryType:UITableViewCellAccessoryNone];
		[cell setSelectionStyle:UITableViewCellSelectionStyleNone];
	} else {
		[cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
		[cell setSelectionStyle:UITableViewCellSelectionStyleBlue];
	}

	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSString *title = nil;
	NSString *dummy = nil;
	id data = nil;
	DMHierarchyViewControllerGetCellTitleAndDetailAndValue(_data, _dataTitle, indexPath, &title, &dummy, &data);

	if (DMHierarchyViewControllerDataRequiresFullViewController(data)) {
		// Attempt to get the data's "title".
		NSString *label = @"";

		if ([data isKindOfClass:[NSString class]]) {
			label = data;
		} else if ([data isKindOfClass:[NSNumber class]]) {
			label = title;
		} else if ([data isKindOfClass:[NSData class]]) {
			label = title;
		} else if ([data isKindOfClass:[NSArray class]]) {
			label = title;
		} else if ([data isKindOfClass:[NSDictionary class]]) {
			label = title;
		}

		DMHierarchyViewController *viewController = [[DMHierarchyViewController alloc] initWithStyle:UITableViewStyleGrouped backingData:data dataTitle:label];
		[[self navigationController] pushViewController:viewController animated:YES];
		[viewController release];
	}

	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end

BOOL DMHierarchyViewControllerDataRequiresFullViewController(id data)
{
	return !([data isKindOfClass:[NSString class]] || [data isKindOfClass:[NSNumber class]] || [data isKindOfClass:[NSData class]]);
}

NSString *DMHierarchyViewControllerFormattedSmallData(id data)
{
	if ([data isKindOfClass:[NSString class]]) {
		return data;
	} else if ([data isKindOfClass:[NSNumber class]]) {
		return [(NSNumber *)data stringValue];
	} else if ([data isKindOfClass:[NSData class]]) {
		NSString *string = nil;
		if ((string = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease]))
			return string;
		else
			return [data description];
	} else {
		return nil;
	}
}

void DMHierarchyViewControllerGetCellTitleAndDetailAndValue(id data, NSString *dataTitle, NSIndexPath *indexPath, NSString **title, NSString **detail, id *value)
{
	NSInteger row = [indexPath row];

	if ([data isKindOfClass:[NSString class]]) {
		*title = dataTitle;
		*detail = data;
	} else if ([data isKindOfClass:[NSNumber class]]) {
		*title = dataTitle;
		*detail = [data stringValue];
	} else if ([data isKindOfClass:[NSData class]]) {
		*title = dataTitle;
		*detail = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
	} else if ([data isKindOfClass:[NSArray class]]) {
		id val = [data objectAtIndex:row];
		*value = val;
		*title = nil;
		if (!DMHierarchyViewControllerDataRequiresFullViewController(val)) {
			*detail = DMHierarchyViewControllerFormattedSmallData(val);
		} else {
			*detail = nil;
		}
	} else if ([data isKindOfClass:[NSDictionary class]]) {
		NSString *key = [[data allKeys] objectAtIndex:row];
		id val = [data objectForKey:key];
		*value = val;
		*title = key;
		if (!DMHierarchyViewControllerDataRequiresFullViewController(val)) {
			*detail = DMHierarchyViewControllerFormattedSmallData(val);
		} else {
			*detail = nil;
		}
	}
}
