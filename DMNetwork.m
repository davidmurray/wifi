//
//  DHNetwork.m
//
//
//  Created by David Murray on 2013-03-02.
//
//

#import "DMNetwork.h"

@implementation DMNetwork
@synthesize SSID             = _SSID;
@synthesize RSSI             = _RSSI;
@synthesize encryptionModel  = _encryptionModel;
@synthesize BSSID            = _BSSID;
@synthesize username         = _username;
@synthesize password         = _password;
@synthesize vendor           = _vendor;
@synthesize channel          = _channel;
@synthesize APMode           = _APMode;
@synthesize isAppleHotspot   = _isAppleHotspot;
@synthesize isCurrentNetwork = _isCurrentNetwork;
@synthesize isAdHoc          = _isAdhoc;
@synthesize isHidden         = _isHidden;
@synthesize isAssociating    = _isAssociating;
@synthesize requiresUsername = _requiresUsername;
@synthesize requiresPassword = _requiresPassword;
@synthesize networkRef       = _network;

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
    [_encryptionModel release];
    [_BSSID release];
    [_username release];
    [_password release];
    [_vendor release];
    CFRelease(_network);

    [super dealloc];
}


- (NSString *)description
{
    return [NSString stringWithFormat:@"SSID: %@ RSSI: %f Encryption Model: %@ Channel: %i AppleHotspot: %i CurrentNetwork: %i BSSID: %@ AdHoc: %i Hidden: %i Associating: %i", [self SSID], [self RSSI], [self encryptionModel], [self channel], [self isAppleHotspot], [self isCurrentNetwork], [self BSSID], [self isAdHoc], [self isHidden], [self isAssociating]];
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
    else
        [self setEncryptionModel:@"None"];

    // Channel

    CFNumberRef networkChannel = (CFNumberRef)WiFiNetworkGetProperty(_network, CFSTR("CHANNEL"));

    int channel;
    CFNumberGetValue(networkChannel, kCFNumberIntType, &channel);

    [self setChannel:channel];

    // Apple Hotspot

    BOOL isAppleHotspot = WiFiNetworkIsApplePersonalHotspot(_network);
    [self setIsAppleHotspot:isAppleHotspot];

    // BSSID

    NSString *BSSID = (NSString *)WiFiNetworkGetProperty(_network, CFSTR("BSSID"));
    [self setBSSID:BSSID];

    // AdHoc

    BOOL isAdHoc = WiFiNetworkIsAdHoc(_network);
    [self setIsAdHoc:isAdHoc];

    // Hidden

    BOOL isHidden = WiFiNetworkIsHidden(_network);
    [self setIsHidden:isHidden];

    // AP Mode

    int APMode = [(NSNumber *)WiFiNetworkGetProperty(_network, CFSTR("AP_MODE")) intValue];
    [self setAPMode:APMode];

    //NSDictionary *dict = (NSDictionary *)WiFiNetworkCopyRecord(_network);
    //NSLog(@"dict: %@", dict);
    //[dict release];

    // Requires username

    BOOL requiresUsername = WiFiNetworkRequiresUsername(_network);
    [self setRequiresUsername:requiresUsername];

    // Requires password

    BOOL requiresPassword = WiFiNetworkRequiresPassword(_network);
    [self setRequiresPassword:requiresPassword];

    // Vendor
    DMNetworkGetVendorFromMacAddress(BSSID, ^(NSString *retVal, NSError *error) {
        if (error) {
            NSLog(@"[DMNetwork]:[populateData]: Error while getting vendor: %@", [error localizedDescription]);
            [self setVendor:@"N/A"];
        } else {
            NSLog(@"retVal: %@", retVal);
            [self setVendor:retVal];
        }
    });
}

void DMNetworkGetVendorFromMacAddress(NSString *macAddress, DMNetworkGetVendorCompletion completion)
{
    NSString *address = [NSString stringWithFormat:@"%@/%@/%@", kVendorBaseURL, kVendorAPIKey, macAddress];

    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:address]];
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        if (error) {
            completion(nil, error);
            return;
        }

        NSString *result = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];

        if ([result isEqualToString:@"none"] == YES) {
            NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
            [errorDetail setValue:@"Couldn't get vendor because the API returned \"none\"." forKey:NSLocalizedDescriptionKey];

            NSError *anError = [NSError errorWithDomain:@"DMNetworkErrorDomain" code:100 userInfo:errorDetail];
            completion(nil, anError);
            return;
        } else {
            NSRange firstRange = [result rangeOfString:@"<company>"];
            NSRange secondRange = [result rangeOfString:@"</company>"];

            if (firstRange.location != NSNotFound) {
                NSUInteger index = firstRange.location + firstRange.length;
                NSRange finalRange = NSMakeRange(index, secondRange.location - index);

                NSString *retVal = [result substringWithRange:finalRange];
                completion(retVal, nil);
            }
        }
    }];
}

@end
