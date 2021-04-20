export PREFIX = $(THEOS)/toolchain/Xcode11.xctoolchain/usr/bin/

export ARCHS = arm64 arm64e
export TARGET = iphone:clang:13.0:13.0
INSTALL_TARGET_PROCESSES = Instagram Preferences

# https://gist.github.com/haoict/96710faf0524f0ec48c13e405b124222

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = instanoads
instanoads_FILES = $(wildcard *.xm *.m lib/*.m *.swift **/*.swift)
instanoads_FRAMEWORKS = UIKit AVFoundation AVKit
instanoads_EXTRA_FRAMEWORKS = libhdev
instanoads_CFLAGS = -fobjc-arc -Wno-deprecated-declarations -Wno-nullability-completeness

include $(THEOS_MAKE_PATH)/tweak.mk

SUBPROJECTS += pref

include $(THEOS_MAKE_PATH)/aggregate.mk

clean::
	rm -rf .theos packages
