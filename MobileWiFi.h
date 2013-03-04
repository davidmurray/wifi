// Header for MobileWiFi.framework
// Copyright (C) 2013 Cykey (David Murray) david.murray16@hotmail.com
// All rights reserved.

#ifdef __cplusplus
extern "C" {
#endif

    typedef struct __WiFiDeviceClient *WiFiDeviceClientRef;
    typedef struct __WiFiNetwork      *WiFiNetworkRef;
    typedef struct __WiFiManager      *WiFiManagerRef;
    typedef CFErrorRef WiFiErrorRef;

    typedef void (*WiFiManagerScanCallback)(WiFiDeviceClientRef device, CFArrayRef results, WiFiErrorRef error, void *token);

    extern WiFiManagerRef WiFiManagerClientCreate(CFAllocatorRef allocator, int flags);
    extern CFArrayRef WiFiManagerClientCopyDevices(WiFiManagerRef manager);
    extern CFArrayRef WiFiManagerClientCopyNetworks(WiFiManagerRef manager);
    extern WiFiDeviceClientRef WiFiManagerClientGetDevice();
    extern void WiFiManagerClientScheduleWithRunLoop(WiFiManagerRef manager, CFRunLoopRef runLoop, CFStringRef mode);
    extern void WiFiManagerClientUnscheduleFromRunLoop(WiFiManagerRef manager);
    extern void WiFiDeviceClientScanAsync(WiFiDeviceClientRef device, CFDictionaryRef dict, WiFiManagerScanCallback callback, uint32_t flags);

    extern CFPropertyListRef WiFiNetworkGetProperty(WiFiNetworkRef network, CFStringRef property);
    extern int WiFiNetworkGetIntProperty(WiFiNetworkRef network, CFStringRef property);
    extern float WiFiNetworkGetFloatProperty(WiFiNetworkRef network, CFStringRef property);
    extern CFStringRef WiFiNetworkCopyPassword(WiFiNetworkRef);
    extern CFStringRef WiFiNetworkGetSSID(WiFiNetworkRef network);
    extern float WiFiNetworkGetNetworkUsage(WiFiNetworkRef network);
    extern Boolean WiFiNetworkIsWEP(WiFiNetworkRef network);
    extern Boolean WiFiNetworkIsWPA(WiFiNetworkRef network);
    extern Boolean WiFiNetworkIsEAP(WiFiNetworkRef network);
    extern CFDateRef WiFiNetworkGetLastAssociationDate(WiFiNetworkRef network);

    extern CFPropertyListRef WiFiDeviceClientCopyProperty(WiFiDeviceClientRef client, CFStringRef property);
    extern WiFiNetworkRef WiFiDeviceClientCopyCurrentNetwork(WiFiDeviceClientRef client);
    extern int WiFiDeviceClientGetPower(WiFiDeviceClientRef client);

    extern CFStringRef kWiFiATJTestModeEnabledKey;
    extern CFStringRef kWiFiDeviceCapabilitiesKey;
    extern CFStringRef kWiFiDeviceSupportsWAPIKey;
    extern CFStringRef kWiFiDeviceSupportsWoWKey;
    extern CFStringRef kWiFiDeviceVendorIDKey;
    extern CFStringRef kWiFiLocaleTestParamsKey;
    extern CFStringRef kWiFiLoggingDriverFileKey;
    extern CFStringRef kWiFiLoggingDriverLoggingEnabledKey;
    extern CFStringRef kWiFiLoggingEnabledKey;
    extern CFStringRef kWiFiLoggingFileEnabledKey;
    extern CFStringRef kWiFiLoggingFileKey;
    extern CFStringRef kWiFiManagerDisableBlackListKey;
    extern CFStringRef kWiFiNetworkEnterpriseProfileKey;
    extern CFStringRef kWiFiPreferenceCustomNetworksSettingsKey;
    extern CFStringRef kWiFiPreferenceEnhancedWoWEnabledKey;
    extern CFStringRef kWiFiPreferenceMStageAutoJoinKey;
    extern CFStringRef kWiFiRSSIThresholdKey; // '-80'
    extern CFStringRef kWiFiScaledRSSIKey;
    extern CFStringRef kWiFiScaledRateKey;
    extern CFStringRef kWiFiStrengthKey;
    extern CFStringRef kWiFiTetheringCredentialsKey;


#ifdef __cplusplus
}
#endif
