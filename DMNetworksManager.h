//
//  DMNetworksManager.h
//
//
//  Created by David Murray on 2013-03-02.
//
//

#import <UIKit/UIKit.h>
#import "MobileWiFi.h"
#import "DMNetwork.h"

#define kDMNetworksManagerDidStartScanning @"DMNetworksManagerDidStartScanning"
#define kDMNetworksManagerDidFinishScanning @"DMNetworksManagerDidFinishScanning"

@interface DMNetworksManager : NSObject {
    WiFiManagerRef      _manager;
    WiFiDeviceClientRef _client;
    BOOL                _scanning;
    NSMutableArray      *_networks;
}

@property(nonatomic, retain, readonly) NSArray *networks;
@property(nonatomic, assign, readonly, getter = isScanning) BOOL scanning;
@property(nonatomic, assign, getter = isWiFiEnabled) BOOL wiFiEnabled;

+ (id)sharedInstance;
- (void)reloadNetworks;

@end
