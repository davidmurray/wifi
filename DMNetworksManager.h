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

#define kDMNetworksManagerDidStartScanning     @"DMNetworksManagerDidStartScanning"
#define kDMNetworksManagerDidFinishAssociating @"DMNetworksManagerDidFinishAssociating"
#define kDMNetworksManagerDidStartAssociating  @"DMNetworksManagerDidStartAssociating"
#define kDMNetworksManagerDidFinishScanning    @"DMNetworksManagerDidFinishScanning"
#define kDMWiFiPowerStateDidChange             @"DMWiFiPowerStateDidChange"
#define kDMWiFiLinkDidChange                   @"DMWiFiLinkDidChange"

@interface DMNetworksManager : NSObject {
    WiFiManagerRef      _manager;
    WiFiDeviceClientRef _client;
    WiFiNetworkRef      _currentNetwork;
    BOOL                _scanning;
    BOOL                _associating;
    NSMutableArray      *_networks;
}

@property(nonatomic, retain, readonly) NSArray *networks;
@property(nonatomic, assign, readonly, getter = isScanning) BOOL scanning;
@property(nonatomic, assign, getter = isWiFiEnabled) BOOL wiFiEnabled;

+ (id)sharedInstance;
- (void)reloadNetworks;
- (NSString *)interfaceName;
- (void)associateWithNetwork:(DMNetwork *)network;

@end
