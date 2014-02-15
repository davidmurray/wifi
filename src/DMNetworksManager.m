//
//  DMNetworksManager.m
//
//
//  Created by David Murray on 2013-03-02.
//
//

#import "DMNetworksManager.h"
#import "DMNetwork.h"

@interface DMNetworksManager ()

- (void)_scan;
- (void)_clearNetworks;
- (void)_addNetwork:(DMNetwork *)network;
- (void)_receivedNotificationNamed:(NSString *)name;
- (void)_reloadCurrentNetwork;
- (void)_scanDidFinishWithError:(int)error;
- (void)_associationDidFinishWithError:(int)error;
- (WiFiNetworkRef)_currentNetwork;

static void DMScanCallback(WiFiDeviceClientRef device, CFArrayRef results, int error, const void *token);
static void DMAssociationCallback(WiFiDeviceClientRef device, WiFiNetworkRef networkRef, CFDictionaryRef dict, int error, const void *token);
static void DMReceivedNotification(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo);

@end

static DMNetworksManager *_sharedInstance = nil;

@implementation DMNetworksManager
@synthesize networks = _networks;
@synthesize scanning = _scanning;

+ (id)sharedInstance
{
	@synchronized(self) {
		if (!_sharedInstance)
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
		if (devices) {
			_client = (WiFiDeviceClientRef)CFArrayGetValueAtIndex(devices, 0);
			CFRetain(_client);

			CFRelease(devices);
		}

		CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), self, DMReceivedNotification, CFSTR("com.apple.wifi.powerstatedidchange"), NULL, CFNotificationSuspensionBehaviorCoalesce);
		CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), self, DMReceivedNotification, CFSTR("com.apple.wifi.linkdidchange"), NULL, CFNotificationSuspensionBehaviorCoalesce);
	}

	return self;
}

- (void)dealloc
{
	CFNotificationCenterRemoveObserver(CFNotificationCenterGetDarwinNotifyCenter(), self, NULL, NULL);

	CFRelease(_currentNetwork);
	CFRelease(_client);
	CFRelease(_manager);

	[self _clearNetworks];

	[super dealloc];
}

- (void)scan
{
	// Prevent initiating a scan when we're already scanning.
	if (_scanning)
		return;

	_scanning = YES;

	// Post a notification to tell the controller that scanning has started.
	[[NSNotificationCenter defaultCenter] postNotificationName:kDMNetworksManagerDidStartScanning object:nil];

	// Reload the current network.
	[self _reloadCurrentNetwork];

	// Actually initiate a scan.
	[self _scan];
}

- (void)associateWithNetwork:(DMNetwork *)network
{
	// Prevent initiating an association if we're already associating.
	if (_associating)
		return;

	if (_currentNetwork) {
		// Prevent associating if we're already associated with that network.
		if ([[network BSSID] isEqualToString:(NSString *)WiFiNetworkGetProperty(_currentNetwork, CFSTR("BSSID"))]) {
			return;
		} else {
			// Disassociate with the current network before associating with a new one.
			[self disassociate];
		}
	}

	WiFiManagerClientScheduleWithRunLoop(_manager, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);

	WiFiNetworkRef net = [network _networkRef];

	if (net) {
		// XXX: Figure out how Apple sets the username.
		if ([network password])
			WiFiNetworkSetPassword(net, (CFStringRef)[network password]);

		WiFiDeviceClientAssociateAsync(_client, net, DMAssociationCallback, NULL);
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

- (NSArray *)knownNetworks
{
	return [(NSArray *)WiFiManagerClientCopyNetworks(_manager) autorelease];
}

- (void)removeNetwork:(WiFiNetworkRef)network
{
	WiFiManagerClientRemoveNetwork(_manager, network);
}

- (void)disassociate
{
	WiFiDeviceClientDisassociate(_client);

	[[NSNotificationCenter defaultCenter] postNotificationName:kDMNetworksManagerDidDisassociate object:nil];
}

#pragma mark - Private APIs

- (void)_scan
{
	WiFiManagerClientScheduleWithRunLoop(_manager, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
	WiFiDeviceClientScanAsync(_client, (CFDictionaryRef)[NSDictionary dictionary], DMScanCallback, NULL);
}

- (void)_clearNetworks
{
	[_networks release];
	_networks = nil;
}

- (void)_addNetwork:(DMNetwork *)network
{
	if (!_networks)
		_networks = [[NSMutableArray alloc] init];

	[_networks addObject:network];
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

- (void)_scanDidFinishWithError:(int)error
{
	WiFiManagerClientUnscheduleFromRunLoop(_manager);

	// Reverse the array so that networks with the highest signal strength go to the top.
	NSArray *tempNetworks = [[_networks reverseObjectEnumerator] allObjects];
	[_networks removeAllObjects];
	[_networks addObjectsFromArray:tempNetworks];

	_scanning = NO;

	if (error != 0) {
		NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:error], kDMErrorValueKey, nil];
		[[NSNotificationCenter defaultCenter] postNotificationName:kDMNetworksManagerScanningDidFail object:nil userInfo:userInfo];
	} else {
		// Post a notification to tell the controller that scanning has finished.
		[[NSNotificationCenter defaultCenter] postNotificationName:kDMNetworksManagerDidFinishScanning object:nil];
	}
}

- (void)_associationDidFinishWithError:(int)error
{
	WiFiManagerClientUnscheduleFromRunLoop(_manager);

	for (DMNetwork *network in [[DMNetworksManager sharedInstance] networks]) {
		if ([network isAssociating])
			[network setIsAssociating:NO];
	}

	_associating = NO;

	// Reload the current network.
	[self _reloadCurrentNetwork];

	if (error != 0) {
		NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:error], kDMErrorValueKey, nil];
		[[NSNotificationCenter defaultCenter] postNotificationName:kDMNetworksManagerAssociatingDidFail object:nil userInfo:userInfo];
	} else {
		// Post a notification to tell the controller that association has finished.
		[[NSNotificationCenter defaultCenter] postNotificationName:kDMNetworksManagerDidFinishAssociating object:nil];
	}
}

#pragma mark - Functions

static void DMScanCallback(WiFiDeviceClientRef device, CFArrayRef results, int error, const void *token)
{
	[[DMNetworksManager sharedInstance] _clearNetworks];

	for (unsigned x = 0; x < CFArrayGetCount(results); x++) {
		WiFiNetworkRef networkRef = (WiFiNetworkRef)CFArrayGetValueAtIndex(results, x);

		DMNetwork *network = [[DMNetwork alloc] initWithNetwork:networkRef];
		[network populateData];

		WiFiNetworkRef currentNetwork = [[DMNetworksManager sharedInstance] _currentNetwork];

		// WiFiNetworkGetProperty() crashes if the network parameter is NULL therefore we need to check if it exists first.
		if (currentNetwork) {
			if ([[network BSSID] isEqualToString:(NSString *)WiFiNetworkGetProperty(currentNetwork, CFSTR("BSSID"))])
				[network setIsCurrentNetwork:YES];
		}

		[[DMNetworksManager sharedInstance] _addNetwork:network];

		[network release];
	}

	[[DMNetworksManager sharedInstance] _scanDidFinishWithError:error];
}

static void DMAssociationCallback(WiFiDeviceClientRef device, WiFiNetworkRef networkRef, CFDictionaryRef dict, int error, const void *token)
{
	// Reload every network's data.
	for (DMNetwork *network in [[DMNetworksManager sharedInstance] networks]) {
		[network populateData];

		if (networkRef) {
			[network setIsCurrentNetwork:[[network BSSID] isEqualToString:(NSString *)WiFiNetworkGetProperty(networkRef, CFSTR("BSSID"))]];
		}
	}

	[[DMNetworksManager sharedInstance] _associationDidFinishWithError:error];
}

static void DMReceivedNotification(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
	[(DMNetworksManager *)observer _receivedNotificationNamed:(NSString *)name];
}

@end
