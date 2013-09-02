//
//  DMNetworksManager.m
//
//
//  Created by David Murray on 2013-03-02.
//
//

#import "DMNetworksManager.h"

@interface DMNetworksManager (Private)

- (void)_scan;
- (void)_clearNetworks;
- (void)_addNetwork:(DMNetwork *)network;
- (void)_scanningDidEnd;
- (void)_scanningDidFail;
- (void)_associationDidEnd;
- (void)_disassociate;
- (void)_receivedNotificationNamed:(NSString *)name;
- (void)_reloadCurrentNetwork;
- (WiFiNetworkRef)_currentNetwork;

static void scanCallback(WiFiDeviceClientRef device, CFArrayRef results, CFErrorRef error, void *token);
static void associationCallback(WiFiDeviceClientRef device, WiFiNetworkRef networkRef, CFDictionaryRef dict, CFErrorRef error, void *token);
static void receivedNotification(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo);

@end

static DMNetworksManager *_sharedInstance = nil;

@implementation DMNetworksManager
@synthesize networks = _networks;
@synthesize scanning = _scanning;

+ (id)sharedInstance
{
	@synchronized(self) {
		if (_sharedInstance == nil)
			_sharedInstance = [[self alloc] init];

		return _sharedInstance;
	}
}

- (id)init
{
	self = [super init];

	if (self) {
		_manager = WiFiManagerClientCreate(kCFAllocatorDefault, 0);

		CFArrayRef devices = WiFiManagerClientCopyDevices(_manager);
		_client = (WiFiDeviceClientRef)CFArrayGetValueAtIndex(devices, 0);

		CFRelease(devices);

		CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, receivedNotification, CFSTR("com.apple.wifi.powerstatedidchange"), NULL, CFNotificationSuspensionBehaviorCoalesce);
		CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, receivedNotification, CFSTR("com.apple.wifi.linkdidchange"), NULL, CFNotificationSuspensionBehaviorCoalesce);
	}

	return self;
}

- (void)dealloc
{
	CFRelease(_manager);
	CFNotificationCenterRemoveObserver(CFNotificationCenterGetDarwinNotifyCenter(), receivedNotification, NULL, NULL);
	CFRelease(_currentNetwork);

	[self _clearNetworks];

	[super dealloc];
}

- (void)reloadNetworks
{
	// Prevent initiating a scan when we're already scanning.
	if (_scanning == YES)
		return;

	_scanning = YES;

	// Post a notification to tell the controller that scanning has started.
	[[NSNotificationCenter defaultCenter] postNotificationName:kDMNetworksManagerDidStartScanning object:nil];

	// Reload the current network.
	[self _reloadCurrentNetwork];

	// Initiate a scan.
	[self _scan];
}

- (void)associateWithNetwork:(DMNetwork *)network
{
	// Prevent initiating an association if we're already associating.
	if (_associating == YES)
		return;

	if (_currentNetwork) {
		// Prevent associating if we're already associated with that network.
		if ([[network BSSID] isEqualToString:(NSString *)WiFiNetworkGetProperty(_currentNetwork, CFSTR("BSSID"))]) {
			return;
		} else {
			// Disassociate with the current network before associating with a new one.
			[self _disassociate];
		}
	}

	WiFiManagerClientScheduleWithRunLoop(_manager, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);

	WiFiNetworkRef net = [network networkRef];

	if (net) {
		// XXX: Figure out how Apple sets the username.
		if ([network password])
			WiFiNetworkSetPassword(net, (CFStringRef)[network password]);

		WiFiDeviceClientAssociateAsync(_client, net, associationCallback, NULL);
		[network setIsAssociating:YES];
		_associating = YES;
	}

	// Post a notification to tell the controller that association has started.
	[[NSNotificationCenter defaultCenter] postNotificationName:kDMNetworksManagerDidStartAssociating object:nil];
}

- (BOOL)isWiFiEnabled
{
	CFBooleanRef enabled = WiFiManagerClientCopyProperty(_manager, CFSTR("AllowEnable"));

	BOOL value = CFBooleanGetValue(enabled);

	CFRelease(enabled);

	return value;
}

- (void)setWiFiEnabled:(BOOL)enabled
{
	// XXX: What.
	CFBooleanRef value = (enabled ? kCFBooleanTrue : kCFBooleanFalse);

	WiFiManagerClientSetProperty(_manager, CFSTR("AllowEnable"), value);
}

- (NSString *)interfaceName
{
	return (NSString *)WiFiDeviceClientGetInterfaceName(_client);
}

#pragma mark - Private APIs

- (void)_scan
{
	// TODO: Implement kDMNetworksManagerDidBeginScanning.
	WiFiManagerClientScheduleWithRunLoop(_manager, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
	WiFiDeviceClientScanAsync(_client, (CFDictionaryRef)[NSDictionary dictionary], scanCallback, 0);
}

- (void)_clearNetworks
{
	[_networks release];
	_networks = nil;
}

- (void)_addNetwork:(DMNetwork *)network
{
	if (_networks == nil)
		_networks = [[NSMutableArray alloc] init];

	[_networks addObject:network];
}

- (void)_disassociate
{
	WiFiDeviceClientDisassociate(_client);
}

- (void)_scanningDidEnd
{
	// Reverse the array so that networks with the highest signal strength go to the top.
	NSArray *tempNetworks = [[_networks reverseObjectEnumerator] allObjects];
	[_networks removeAllObjects];
	[_networks addObjectsFromArray:tempNetworks];

	_scanning = NO;

	// Post a notification to tell the controller that scanning has finished.
	[[NSNotificationCenter defaultCenter] postNotificationName:kDMNetworksManagerDidFinishScanning object:nil];

	// GTFO THE RUN LOOP.
	WiFiManagerClientUnscheduleFromRunLoop(_manager);
}

- (void)_scanningDidFail;
{
	_scanning = NO;
}

- (void)_associationDidEnd
{
	WiFiManagerClientUnscheduleFromRunLoop(_manager);

	for (DMNetwork *network in [[DMNetworksManager sharedInstance] networks]) {
		if ([network isAssociating])
			[network setIsAssociating:NO];
	}

	_associating = NO;

	// Reload the current network.
	[self _reloadCurrentNetwork];

	// Post a notification to tell the controller that association has finished.
	[[NSNotificationCenter defaultCenter] postNotificationName:kDMNetworksManagerDidFinishAssociating object:nil];
}

- (WiFiNetworkRef)_currentNetwork
{
	return _currentNetwork;
}

- (void)_reloadCurrentNetwork
{
	if (_currentNetwork) {
		CFRelease(_currentNetwork);
		_currentNetwork = nil;
	}

	_currentNetwork = WiFiDeviceClientCopyCurrentNetwork(_client);
}

- (void)_receivedNotificationNamed:(NSString *)name
{
	if ([name isEqualToString:@"com.apple.wifi.powerstatedidchange"]) {
		[[NSNotificationCenter defaultCenter] postNotificationName:kDMWiFiPowerStateDidChange object:nil];
	} else if ([name isEqualToString:@"com.apple.wifi.linkdidchange"]) {
		[self _reloadCurrentNetwork];
		[[NSNotificationCenter defaultCenter] postNotificationName:kDMWiFiLinkDidChange object:nil];
	}
}

#pragma mark - Functions

static void scanCallback(WiFiDeviceClientRef device, CFArrayRef results, CFErrorRef error, void *token)
{
	DMNetworksManager *manager = [DMNetworksManager sharedInstance];

	if (error) {
		CFStringRef errorDescription = CFErrorCopyDescription(error);
		NSLog(@"[%s] Error while scanning: %@", __FUNCTION__, errorDescription);
		CFRelease(errorDescription);

		[manager _scanningDidFail];

		return;
	}

	[manager _clearNetworks];

	for (unsigned x = 0; x < CFArrayGetCount(results); x++) {
		WiFiNetworkRef networkRef = (WiFiNetworkRef)CFArrayGetValueAtIndex(results, x);

		DMNetwork *network = [[DMNetwork alloc] initWithNetwork:networkRef];
		[network populateData];

		WiFiNetworkRef currentNetwork = [manager _currentNetwork];

		// WiFiNetworkGetProperty() crashes if the network parameter is NULL therefore we need to check if it exists first.
		if (currentNetwork) {
			if ([[network BSSID] isEqualToString:(NSString *)WiFiNetworkGetProperty(currentNetwork, CFSTR("BSSID"))])
				[network setIsCurrentNetwork:YES];
		}

		[manager _addNetwork:network];

		[network release];
	}

	[manager _scanningDidEnd];
}

static void associationCallback(WiFiDeviceClientRef device, WiFiNetworkRef networkRef, CFDictionaryRef dict, CFErrorRef error, void *token)
{
	if (error) {
		CFStringRef errorDescription = CFErrorCopyDescription(error);
		NSLog(@"[%s] Error while associating: %@", __FUNCTION__, errorDescription);
		CFRelease(errorDescription);
		return;
	}

	// Reload every network's data.
	for (DMNetwork *network in [[DMNetworksManager sharedInstance] networks]) {
		[network populateData];

		if (networkRef) {
			if ([[network BSSID] isEqualToString:(NSString *)WiFiNetworkGetProperty(networkRef, CFSTR("BSSID"))])
				[network setIsCurrentNetwork:YES];
		}
	}

	[[DMNetworksManager sharedInstance] _associationDidEnd];
}

static void receivedNotification(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
	[[DMNetworksManager sharedInstance] _receivedNotificationNamed:(NSString *)name];
}

@end
