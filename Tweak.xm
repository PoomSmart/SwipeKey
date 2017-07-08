#define CHECK_TARGET
#import "../PS.h"

BOOL enabled = YES;
NSInteger popupState = isiOS7Up ? 4 : 1;
NSInteger normalState = isiOS7Up ? 2 : 4;

NSArray *whitelist() {
    return @[@"International-Key", @"Return-Key", @"Shift-Key", @"More-Key", @"Dictation-Key", @"Dismiss-Key"];
}

%hook UIKeyboardLayoutStar

%group iOS9Up

// shouldRetestTouchDraggedFromKey
// performHitTestForTouchInfo:touchStage:executionContextPassingUIKBTree:
- (void)touchDragged: (UITouch *)touch executionContext: (UIKeyboardTaskExecutionContext *)context {
    if (enabled) {
        UIKeyboardTouchInfo *touchInfo = [self infoForTouch:touch];
        UIKBTree *key = [self keyHitTest:[touchInfo.touch locationInView:self]];
        BOOL isOut = [self touchPassesDragThreshold:touchInfo];
        BOOL filter = ![whitelist() containsObject:key.name];
        BOOL noPopup = self.activeKey.state != 16;
        if (isOut && filter && noPopup && key.state == normalState) {
            NSLog(@"%@", touchInfo);
            [self completeHitTestForTouchDragged:touchInfo hitKey:touchInfo.key];
            [self touchUp:touch executionContext:context];
            [self touchDown:touch];
            return;
        }
    }
    %orig;
}

%end

%group iOS78

- (void)touchDragged: (UITouch *)touch executionContext: (UIKeyboardTaskExecutionContext *)context {
    if (enabled) {
        UIKeyboardTouchInfo *touchInfo = [self infoForTouch:touch];
        UIKBTree *key = [self keyHitTest:[touchInfo.touch locationInView:self]];
        BOOL isOut = [self touchPassesDragThreshold:touchInfo];
        BOOL filter = ![whitelist() containsObject:key.name];
        BOOL noPopup = self.activeKey.state != 16;
        if (isOut && filter && noPopup && key.state == normalState) {
            [self completeHitTestForTouchDragged:touchInfo hitKey:touchInfo.key];
            [self touchUp:touch executionContext:context];
            [self touchDown:touch];
            return;
        }
    }
    %orig;
}

%end

%group iOS6Down

- (void)touchDragged: (UITouch *)touch {
    if (enabled) {
        UIKeyboardTouchInfo *touchInfo = [self infoForTouch:touch];
        UIKBTree *key = [self keyHitTest:[touchInfo.touch locationInView:self]];
        BOOL filter = ![whitelist() containsObject:key.name];
        BOOL noPopup = [self stateForKey:self.activeKey] != 16;
        if (filter && noPopup && [self stateForKey:key] == normalState) {
            [self touchUp:touch];
            [self touchDown:touch];
            return;
        }
    }
    %orig;
}

%end

%end

#ifndef TARGET_OS_SIMULATOR

CFStringRef PreferencesNotification = CFSTR("com.PS.SwipeKey.prefs");

static void prefs() {
    CFPreferencesAppSynchronize(CFSTR("com.PS.SwipeKey"));
    NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.PS.SwipeKey.plist"];
    id val = prefs[@"enabled"];
    enabled = val ? [val boolValue] : YES;
}

static void prefsChanged(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo){
    prefs();
}

#endif

%ctor {
    if (isTarget(TargetTypeGUINoExtension)) {
        #ifndef TARGET_OS_SIMULATOR
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, &prefsChanged, PreferencesNotification, NULL, CFNotificationSuspensionBehaviorCoalesce);
        prefs();
        #endif
        if (isiOS9Up) {
            %init(iOS9Up);
        }
        if (isiOS7Up) {
            %init(iOS78);
        } else {
            %init(iOS6Down);
        }
    }
}
