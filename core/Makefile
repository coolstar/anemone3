include $(THEOS)/makefiles/common.mk

TWEAK_NAME = AnemoneCore
AnemoneCore_FILES = ANEMSettingsManager.mm Bundle.m CGImage.xm
AnemoneCore_FRAMEWORKS = CoreGraphics ImageIO
AnemoneCore_CFLAGS = -fobjc-arc
ifeq ($(NO_SUBSTRATE),1)
ifeq ($(USE_SUBSTITUTE),1)
		AnemoneCore_CFLAGS += -DNO_SUBSTRATE -DUSE_SUBSTITUTE
else
		AnemoneCore_FILES += ../common/fishhook.c
		AnemoneCore_CFLAGS += -DNO_SUBSTRATE
endif
		AnemoneCore_USE_SUBSTRATE=0
endif

AnemoneCore_LDFLAGS = -Wl,-segalign,4000 -L../common
ifeq ($(USE_SUBSTITUTE),1)
AnemoneCore_LDFLAGS += -lsubstitute
endif

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 backboardd"
