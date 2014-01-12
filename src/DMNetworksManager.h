//
//  DMNetworksManager.h
//
//
//  Created by David Murray on 2013-03-02.
//
//

#import <UIKit/UIKit.h>
#import "MobileWiFi/MobileWiFi.h"
#import "DMNetwork.h"

#define kDMNetworksManagerDidStartScanning     @"DMNetworksManagerDidStartScanning"
#define kDMNetworksManagerDidFinishScanning    @"DMNetworksManagerDidFinishScanning"
#define kDMNetworksManagerScanningDidFail      @"DMNetworksManagerScanningDidFail"
#define kDMNetworksManagerDidStartAssociating  @"DMNetworksManagerDidStartAssociating"
#define kDMNetworksManagerDidFinishAssociating @"DMNetworksManagerDidFinishAssociating"
#define kDMNetworksManagerAssociatingDidFail   @"DMNetworksManagerAssociatingDidFail"
#define kDMNetworksManagerDidDisassociate      @"DMNetworksManagerDidDisassociate"
#define kDMWiFiPowerStateDidChange             @"DMWiFiPowerStateDidChange"
#define kDMWiFiLinkDidChange                   @"DMWiFiLinkDidChange"
#define kDMErrorValueKey					   @"DMErrorValueKey"

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
- (NSArray *)knownNetworks;
- (void)removeNetwork:(WiFiNetworkRef)network;
- (void)disassociate;

@end
