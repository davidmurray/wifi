//
//  DMNetworksManager.h
//
//
//  Created by David Murray on 2013-03-02.
//
//

#import <UIKit/UIKit.h>
#import "MobileWiFi/MobileWiFi.h"

@class DMNetwork;

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
- (void)scan;
- (void)removeNetwork:(WiFiNetworkRef)network;
- (void)associateWithNetwork:(DMNetwork *)network;
- (void)disassociate;
- (NSArray *)knownNetworks;
- (NSString *)interfaceName;

@end
