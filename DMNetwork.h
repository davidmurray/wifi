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
    int            _RSSI;
}

@property(nonatomic, copy) NSString *SSID;
@property(nonatomic, assign) int RSSI;

- (id)initWithNetwork:(WiFiNetworkRef)network;
- (void)populateData;

@end
