export PREFIX = $(THEOS)/toolchain/XcodeDefault-11.5.xctoolchain/usr/bin/
export ARCHS = arm64 arm64e
export TARGET = iphone:clang:13.6:12.0

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = INAPref
INAPref_FILES = $(wildcard *.m)
INAPref_INSTALL_PATH = /Library/PreferenceBundles
INAPref_PRIVATE_FRAMEWORKS = Preferences
INAPref_EXTRA_FRAMEWORKS = libhdev
INAPref_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/INAPref.plist$(ECHO_END)
