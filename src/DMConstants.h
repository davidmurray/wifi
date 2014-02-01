// Notifications
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

// NSUserDefaults keys
#define kDMAutoScanEnabledKey  @"DMAutoScanEnabledKey"
#define kDMAutoScanIntervalKey @"DMAutoScanIntervalKey"

// UIView tags
#define kDMWiFiEnabledSwitchTag     0011
#define kDMAutoScanEnabledSwitchTag 0022

// CoreFoundation versions
#ifndef kCFCoreFoundationVersionNumber_iOS_7_0
#define kCFCoreFoundationVersionNumber_iOS_7_0 847.20
#endif