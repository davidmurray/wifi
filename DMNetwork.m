//
//  DHNetwork.m
//
//
//  Created by David Murray on 2013-03-02.
//
//

#import "DMNetwork.h"

@implementation DMNetwork
@synthesize SSID = _SSID;
@synthesize RSSI = _RSSI;

- (id)initWithNetwork:(WiFiNetworkRef)network
{
    self = [super init];

    if (self) {
        _network = (WiFiNetworkRef)CFRetain(network);
    }

    return self;
}

- (void)dealloc
{
    [_SSID release];
    CFRelease(_network);

    [super dealloc];
}

/*
- (NSString *)description
{
    return [NSString stringWithFormat:@"[%@] SSID: %@ RSSI: %i", self, [self SSID], [self RSSI]];
}
*/

- (void)populateData
{
    // SSID

    NSString *SSID = (NSString *)WiFiNetworkGetSSID(_network);
    [self setSSID:SSID];

    // RSSI

    CFNumberRef RSSI = (CFNumberRef)WiFiNetworkGetProperty(_network, kWiFiScaledRSSIKey);

    float strength;
    CFNumberGetValue(RSSI, kCFNumberFloatType, &strength);

    strength = strength * 100;

    // Round to the nearest integer.
    strength = ceilf(strength);

    // Convert to a negative number.
    strength = strength * -1;

    NSLog(@"WiFi signal strength: %f dBm", strength);

    [self setRSSI:(int)RSSI];
}


@end
