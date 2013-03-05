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
    float          _RSSI;
    int            _channel;
    BOOL           _isAppleHotspot;
    BOOL           _isCurrentNetwork;
}

@property(nonatomic, copy) NSString *SSID;
@property(nonatomic, copy) NSString *encryptionModel;
@property(nonatomic, assign) float RSSI;
@property(nonatomic, assign) int channel;
@property(nonatomic, assign) BOOL isAppleHotspot;
@property(nonatomic, assign) BOOL isCurrentNetwork;

- (id)initWithNetwork:(WiFiNetworkRef)network;
- (void)populateData;

@end
