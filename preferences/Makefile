include $(THEOS)/makefiles/common.mk

TWEAK_NAME = AnemonePreferences
AnemonePreferences_FILES = Tweak.x

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
