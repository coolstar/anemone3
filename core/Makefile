include $(THEOS)/makefiles/common.mk

TWEAK_NAME = AnemoneCore
AnemoneCore_FILES = ANEMSettingsManager.mm Bundle.m CGImage.xm
AnemoneCore_FRAMEWORKS = CoreGraphics ImageIO
AnemoneCore_CFLAGS = -fobjc-arc
AnemoneCore_USE_SUBSTRATE=0

AnemoneCore_LDFLAGS = -L../common -lsubstitute

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 backboardd"
