ARCHS = arm64 arm64e
TARGET = iphone:clang:12.4:10.0
INSTALL_TARGET_PROCESSES = Instagram Preferences

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = instanoads
instanoads_FILES = $(wildcard *.xm *.m)
instanoads_EXTRA_FRAMEWORKS = libhdev
instanoads_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk

SUBPROJECTS += pref

include $(THEOS_MAKE_PATH)/aggregate.mk

clean::
	rm -rf .theos packages