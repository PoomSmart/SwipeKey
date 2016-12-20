DEBUG = 0
SIMULATOR = 0

ifeq ($(SIMULATOR),1)
	TARGET = simulator:clang:latest
	ARCHS = x86_64 i386
else
	TARGET = iphone:clang:latest
	ARCHS = armv7 arm64
endif

PACKAGE_VERSION = 1.0.1

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = SwipeKey
SwipeKey_FILES = Tweak.xm

include $(THEOS_MAKE_PATH)/tweak.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp -R Resources $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/SwipeKey$(ECHO_END)
	$(ECHO_NOTHING)find $(THEOS_STAGING_DIR) -name .DS_Store | xargs rm -rf$(ECHO_END)

all::
ifeq ($(SIMULATOR),1)
	@cp -v $(PWD)/.theos/$(THEOS_OBJ_DIR_NAME)/*.dylib /opt/simject
	@cp -v $(PWD)/*.plist /opt/simject
endif