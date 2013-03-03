include theos/makefiles/common.mk


APPLICATION_NAME = WiFi
WiFi_FILES = main.m WiFiApplication.mm DMNetworksViewController.m DMNetworksManager.m DMNetwork.m DMDetailViewController.m
WiFi_FRAMEWORKS = UIKit CoreGraphics
WiFi_PRIVATE_FRAMEWORKS = MobileWiFi
WiFi_CODESIGN_FLAGS = -Sentitlements.xml


include $(THEOS_MAKE_PATH)/application.mk
