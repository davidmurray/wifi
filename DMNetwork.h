//
//  DMNetwork.h
//
//
//  Created by David Murray on 2013-03-02.
//
//

#import <UIKit/UIKit.h>
#import "MobileWiFi.h"

#define kVendorBaseURL @"http://www.macvendorlookup.com/api/"
#define kVendorAPIKey  @"CBZBXAV"

typedef void (^DMNetworkGetVendorCompletion)(NSString *retVal, NSError *error);

@interface DMNetwork : NSObject {
    WiFiNetworkRef _network;
    NSString       *_SSID;
    NSString       *_encryptionModel;
    NSString       *_BSSID;
    NSString       *_username;
    NSString       *_password;
    NSString       *_vendor;
    float          _RSSI;
    int            _channel;
    int            _APMode;
    BOOL           _isAppleHotspot;
    BOOL           _isCurrentNetwork;
    BOOL           _isAdHoc;
    BOOL           _isHidden;
    BOOL           _isAssociating;
    BOOL           _requiresUsername;
    BOOL           _requiresPassword;
}

@property(nonatomic, copy) NSString *SSID;
@property(nonatomic, copy) NSString *encryptionModel;
@property(nonatomic, copy) NSString *BSSID;
@property(nonatomic, copy) NSString *password;
@property(nonatomic, copy) NSString *username;
@property(nonatomic, copy) NSString *vendor;
@property(nonatomic, assign) float RSSI;
@property(nonatomic, assign) int channel;
@property(nonatomic, assign) int APMode;
@property(nonatomic, assign) BOOL isAppleHotspot;
@property(nonatomic, assign) BOOL isCurrentNetwork;
@property(nonatomic, assign) BOOL isAdHoc;
@property(nonatomic, assign) BOOL isHidden;
@property(nonatomic, assign) BOOL isAssociating;
@property(nonatomic, assign) BOOL requiresPassword;
@property(nonatomic, assign) BOOL requiresUsername;
@property(nonatomic, assign, readonly) WiFiNetworkRef networkRef;

- (id)initWithNetwork:(WiFiNetworkRef)network;
- (void)populateData;

void DMNetworkGetVendorFromMacAddress(NSString *macAddress, DMNetworkGetVendorCompletion completion);
@end
