include $(THEOS)/makefiles/common.mk

TWEAK_NAME = AnemoneIcons
AnemoneIcons_FILES = Tweak.x
AnemoneIcons_FRAMEWORKS = MobileCoreServices
AnemoneIcons_PRIVATE_FRAMEWORKS = MobileIcons
AnemoneIcons_CFLAGS = -fobjc-arc
AnemoneIcons_LDFLAGS = -F. -lsubstitute
AnemoneIcons_USE_SUBSTRATE = 0

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
