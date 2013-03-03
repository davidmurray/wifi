//
//  DHNetwork.m
//
//
//  Created by David Murray on 2013-03-02.
//
//

#import "DMNetwork.h"

@implementation DMNetwork
@synthesize SSID            = _SSID;
@synthesize RSSI            = _RSSI;
@synthesize encryptionModel = _encryptionModel;

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


- (NSString *)description
{
    return [NSString stringWithFormat:@"[%@] SSID: %@ RSSI: %f", self, [self SSID], [self RSSI]];
}

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

    [self setRSSI:strength];

    // Encryption model

    if (WiFiNetworkIsWEP(_network))
        [self setEncryptionModel:@"WEP"];
    else if (WiFiNetworkIsWPA(_network))
        [self setEncryptionModel:@"WPA"];
    else if (WiFiNetworkIsEAP(_network))
        [self setEncryptionModel:@"EAP"];
    else
        [self setEncryptionModel:@"None"];
}

@end
