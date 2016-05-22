#import "../PS.h"

@interface UIKBTree : NSObject
@property NSInteger state;
@property NSInteger type;
@property NSInteger visualStyle;
@property NSInteger interactionType;
@property NSInteger displayType;
@property NSInteger variantType;
@property int rendering;
@property BOOL ghost;
- (NSString *)name;
@end

@interface UIKBKeyplaneView : UIView
@end

@interface UIKeyboardTouchInfo : NSObject
@property(retain, nonatomic) UITouch *touch;
@property(retain, nonatomic) UIKBTree* key;
@property(retain, nonatomic) UIKBTree *keyplane;
@property(retain, nonatomic) UIKBTree *slidOffKey;
@property(assign, nonatomic) CGPoint initialPoint;
@property(assign, nonatomic) CGPoint initialDragPoint;
@property int stage;
@property BOOL dragged;
@property BOOL maySuppressUpAction;
@end

@interface UIKeyboardLayoutStar : UIView
@property(retain, nonatomic) UIKBTree *activeKey;
- (BOOL)touchPassesDragThreshold:(UIKeyboardTouchInfo *)touchInfo;
- (UIKeyboardTouchInfo *)infoForTouch:(UITouch *)touch;
- (UIKeyboardTouchInfo *)generateInfoForTouch:(UITouch *)touch;
- (UIKBTree *)keyHitTest:(CGPoint)point;
- (void)touchDown:(UITouch *)touch;
- (void)touchUp:(UITouch *)touch executionContext:(id)context;
- (void)touchUp:(UITouch *)touch;
- (void)completeHitTestForTouchDragged:(UIKeyboardTouchInfo *)touchInfo hitKey:(UIKBTree *)key;
- (int)stateForKey:(UIKBTree *)key;
@end

BOOL enabled;
NSInteger popupState = isiOS7Up ? 4 : 1;
NSInteger normalState = isiOS7Up ? 2 : 4;

NSArray *whitelist()
{
	return @[@"International-Key", @"Return-Key", @"Shift-Key", @"More-Key", @"Dictation-Key", @"Dismiss-Key"];
}

%hook UIKeyboardLayoutStar

%group iOS7Up

- (void)touchDragged:(UITouch *)touch executionContext:(id)context
{
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

- (void)touchDragged:(UITouch *)touch
{
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

CFStringRef PreferencesNotification = CFSTR("com.PS.SwipeKey.prefs");

static void prefs()
{
	CFPreferencesAppSynchronize(CFSTR("com.PS.SwipeKey"));
	NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.PS.SwipeKey.plist"];
	id val = prefs[@"enabled"];
	enabled = val ? [val boolValue] : YES;
}

static void prefsChanged(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
	prefs();
}

%ctor
{
	NSArray *args = [[NSClassFromString(@"NSProcessInfo") processInfo] arguments];
	NSUInteger count = args.count;
	if (count != 0) {
		NSString *executablePath = args[0];
		if (executablePath) {
			BOOL isApplication = [executablePath rangeOfString:@"/Application"].location != NSNotFound;
			BOOL isSpringBoard = [[executablePath lastPathComponent] isEqualToString:@"SpringBoard"];
			if (isApplication || isSpringBoard) {
				CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, &prefsChanged, PreferencesNotification, NULL, CFNotificationSuspensionBehaviorCoalesce);
				prefs();
				if (isiOS7Up) {
					%init(iOS7Up);
				} else {
					%init(iOS6Down);
				}
			}
		}
	}
}