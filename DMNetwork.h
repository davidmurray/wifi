//
//  DMNetwork.h
//
//
//  Created by David Murray on 2013-03-02.
//
//

#import <UIKit/UIKit.h>
#import "MobileWiFi.h"

@interface DMNetwork : NSObject {
    WiFiNetworkRef _network;
    NSString       *_SSID;
    NSString       *_encryptionModel;
    NSString       *_BSSID;
    float          _RSSI;
    int            _channel;
    int            _APMode;
    BOOL           _isAppleHotspot;
    BOOL           _isCurrentNetwork;
    BOOL           _isAdHoc;
    BOOL           _isHidden;
}

@property(nonatomic, copy) NSString *SSID;
@property(nonatomic, copy) NSString *encryptionModel;
@property(nonatomic, copy) NSString *BSSID;
@property(nonatomic, assign) float RSSI;
@property(nonatomic, assign) int channel;
@property(nonatomic, assign) int APMode;
@property(nonatomic, assign) BOOL isAppleHotspot;
@property(nonatomic, assign) BOOL isCurrentNetwork;
@property(nonatomic, assign) BOOL isAdHoc;
@property(nonatomic, assign) BOOL isHidden;

- (id)initWithNetwork:(WiFiNetworkRef)network;
- (void)populateData;

@end
