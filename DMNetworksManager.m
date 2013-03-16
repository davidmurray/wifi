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
- (void)_associationDidEnd;
- (WiFiNetworkRef)_currentNetwork;

void scanCallback(WiFiDeviceClientRef device, CFArrayRef results, WiFiErrorRef error, void *token);
void associationCallback(WiFiDeviceClientRef device, WiFiNetworkRef networkRef, CFDictionaryRef dict, WiFiErrorRef error, void *token);
void receivedNotification(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo);

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

    if (_currentNetwork) {
        CFRelease(_currentNetwork);
        _currentNetwork = nil;
    }

    // Get the current network.
    _currentNetwork = WiFiDeviceClientCopyCurrentNetwork(_client);

    // Initiate a scan.
    [self _scan];
}

- (void)associateWithNetwork:(DMNetwork *)network
{
    // Prevent initiating an association if we're already associating.
    if (_associating == YES)
        return;

    _associating = YES;

    WiFiManagerClientScheduleWithRunLoop(_manager, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);

    WiFiNetworkRef net = [network networkRef];

    if (net) {
        WiFiNetworkSetPassword(net, CFSTR("PASS_GOES_HERE"));
        WiFiDeviceClientAssociateAsync(_client, net, associationCallback, NULL);
        [network setIsAssociating:YES];
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

- (void)_associationDidEnd
{
    WiFiManagerClientUnscheduleFromRunLoop(_manager);

    for (DMNetwork *network in [[DMNetworksManager sharedInstance] networks]) {
        if ([network isAssociating]) {
            [network setIsAssociating:NO];
        }
    }

    _associating = NO;

    // Post a notification to tell the controller that association has finished.
    [[NSNotificationCenter defaultCenter] postNotificationName:kDMNetworksManagerDidFinishAssociating object:nil];
}

- (WiFiNetworkRef)_currentNetwork
{
    return _currentNetwork;
}

#pragma mark - Functions

void scanCallback(WiFiDeviceClientRef device, CFArrayRef results, WiFiErrorRef error, void *token)
{
    if (error)
        NSLog(@"[scanCallback] Error: %@", error);

    DMNetworksManager *manager = [DMNetworksManager sharedInstance];
    [manager _clearNetworks];

    for (unsigned x = 0; x < CFArrayGetCount(results); x++) {
        WiFiNetworkRef networkRef = (WiFiNetworkRef)CFArrayGetValueAtIndex(results, x);

        DMNetwork *network = [[DMNetwork alloc] initWithNetwork:networkRef];
        [network populateData];

        WiFiNetworkRef currentNetwork = [manager _currentNetwork];

        // WiFiNetworkGetSSID() crashes if the network parameter is NULL therefore we need to check if it exists first.
        if (currentNetwork) {
            if ([[network BSSID] isEqualToString:(NSString *)WiFiNetworkGetProperty(currentNetwork, CFSTR("BSSID"))])
                [network setIsCurrentNetwork:YES];
        }

        [manager _addNetwork:network];

        [network release];
    }

    [manager _scanningDidEnd];
}

void associationCallback(WiFiDeviceClientRef device, WiFiNetworkRef networkRef, CFDictionaryRef dict, WiFiErrorRef error, void *token)
{
    if (error)
        NSLog(@"[associationCallback] Error: %@", error);

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

void receivedNotification(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
    if ([(NSString *)name isEqualToString:@"com.apple.wifi.powerstatedidchange"])
        [[NSNotificationCenter defaultCenter] postNotificationName:kDMWiFiPowerStateDidChange object:nil];
    else if ([(NSString *)name isEqualToString:@"com.apple.wifi.linkdidchange"])
        [[NSNotificationCenter defaultCenter] postNotificationName:kDMWiFiLinkDidChange object:nil];
}

@end
