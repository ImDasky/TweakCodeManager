ARCHS = arm64 arm64e
TARGET = iphone:clang:latest:15.0:arm64
INSTALL_TARGET_PROCESSES = TweakCompiler
THEOS_PACKAGE_SCHEME = rootless

# Set PATH for rootless jailbreak to find system commands
export PATH := /var/jb/usr/bin:/var/jb/bin:$(PATH)

include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = TweakCompiler

TweakCompiler_FILES = $(wildcard TweakCompiler/*.swift)
TweakCompiler_RESOURCE_FILES = TweakCompiler/Info.plist TweakCompiler/Assets.xcassets TweakCompiler/Base.lproj
TweakCompiler_FRAMEWORKS = UIKit SwiftUI Foundation
TweakCompiler_CFLAGS = -fobjc-arc
TweakCompiler_SWIFT_VERSION = 5
TweakCompiler_SWIFTFLAGS = -import-objc-header TweakCompiler/TweakCompiler-Bridging-Header.h
TweakCompiler_CODESIGN_FLAGS = -Sentitlements.plist
TweakCompiler_INSTALL_PATH = /var/jb/Applications

include $(THEOS_MAKE_PATH)/application.mk

after-install::
	install.exec "uicache"
