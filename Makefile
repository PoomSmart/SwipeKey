GO_EASY_ON_ME = 1
TARGET = iphone:latest:5.0
ARCHS = armv7 armv7s arm64
DEBUG = 0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = SwipeKey
SwipeKey_FILES = Tweak.xm
#SwipeKey_LIBRARIES = inspectivec

include $(THEOS_MAKE_PATH)/tweak.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp -R Resources $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/SwipeKey$(ECHO_END)
	$(ECHO_NOTHING)find $(THEOS_STAGING_DIR) -name .DS_Store | xargs rm -rf$(ECHO_END)
