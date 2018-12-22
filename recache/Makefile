include $(THEOS)/makefiles/common.mk

TOOL_NAME = recache
recache_FILES = main.mm
recache_FRAMEWORKS = MobileCoreServices
recache_CFLAGS = -fobjc-arc
recache_LDFLAGS = -L../common
recache_CODESIGN_FLAGS=-SEntitlements.plist

include $(THEOS_MAKE_PATH)/tool.mk
