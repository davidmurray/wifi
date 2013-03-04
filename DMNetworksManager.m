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
    }

    return self;
}

- (void)dealloc
{
    CFRelease(_manager);
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

    [self _scan];
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
    _scanning = NO;

    // Post a notification to tell the controller that scanning has finished.
    [[NSNotificationCenter defaultCenter] postNotificationName:kDMNetworksManagerDidFinishScanning object:nil];

    // GTFO THE RUN LOOP
    WiFiManagerClientUnscheduleFromRunLoop(_manager);
}

void scanCallback(WiFiDeviceClientRef device, CFArrayRef results, WiFiErrorRef error, void *token)
{
    [[DMNetworksManager sharedInstance] _clearNetworks];

    for (unsigned x = 0; x < CFArrayGetCount(results); x++) {
        WiFiNetworkRef networkRef = (WiFiNetworkRef)CFArrayGetValueAtIndex(results, x);

        DMNetwork *network = [[DMNetwork alloc] initWithNetwork:networkRef];

        [network populateData];

        [[DMNetworksManager sharedInstance] _addNetwork:network];

        [network release];
    }

    [[DMNetworksManager sharedInstance] _scanningDidEnd];
}

@end
