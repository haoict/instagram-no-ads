ARCHS = arm64 arm64e
TARGET = iphone::12.0:latest
INSTALL_TARGET_PROCESSES = Instagram

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = instanoads
instanoads_FILES = Tweak.xm
instanoads_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk
