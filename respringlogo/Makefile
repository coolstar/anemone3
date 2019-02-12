include $(THEOS)/makefiles/common.mk

TWEAK_NAME = AnemoneRespringLogo
AnemoneRespringLogo_FILES = Tweak.xm
AnemoneRespringLogo_CFLAGS = -fobjc-arc
AnemoneRespringLogo_USE_SUBSTRATE=0

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
