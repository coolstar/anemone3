include $(THEOS)/makefiles/common.mk

TWEAK_NAME = AnemonePreferences
AnemonePreferences_FILES = Tweak.x
AnemonePreferences_CFLAGS = -fobjc-arc
AnemonePreferences_LDFLAGS = -lhooker
AnemonePreferences_USE_SUBSTRATE = 0

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
