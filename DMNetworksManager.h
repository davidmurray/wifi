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

    NSMutableArray      *_networks;
}

@property(nonatomic, retain, readonly) NSArray *networks;

+ (id)sharedInstance;
- (void)reloadNetworks;

void scanCallback(WiFiDeviceClientRef device, CFArrayRef results, WiFiErrorRef error, void *token);

@end
