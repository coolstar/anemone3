THEOS_PACKAGE_DIR_NAME = debs
TARGET = iphone:clang:latest:11.0
export ARCHS = arm64 arm64e

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Anemone
Anemone_FILES = Calendar.xm AppNotify.x UIColor+HTMLColors.mm
Anemone_FRAMEWORKS = UIKit CoreGraphics QuartzCore MobileCoreServices
Anemone_CFLAGS = -DBOOTSTRAP_DIR='"$(BOOTSTRAP_DIR)"' -fobjc-arc
ifeq ($(ENABLE_WATERMARK), 1)
	Anemone_CFLAGS += -DENABLE_WATERMARK
endif
Anemone_USE_SUBSTRATE=0

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
ifeq ($(RESPRING),0)
	install.exec "killall Anemone; sleep 0.2; sblaunch com.anemonetheming.anemone"
else
	install.exec "killall SpringBoard"
endif

SUBPROJECTS = icons#app core recache cardump icons respringlogo preferences
include $(THEOS_MAKE_PATH)/aggregate.mk
