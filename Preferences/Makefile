ARCHS = arm64 arm64e
include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = HideSenderPreferences
HideSenderPreferences_FILES = HideSenderPreferencesController.m
HideSenderPreferences_INSTALL_PATH = /Library/PreferenceBundles
HideSenderPreferences_FRAMEWORKS = UIKit
HideSenderPreferences_LDFLAGS = ./Preferences.tbd
HideSenderPreferences_LIBRARIES = sparkapplist

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/HideSenderPreferences.plist$(ECHO_END)
