#import <objc/runtime.h>

@interface NCNotificationListCollectionView : UICollectionView
@end

@interface NCNotificationContentView : UIView
@property(nonatomic, retain) NSString * primaryText;
@property(nonatomic, retain) NSString * secondaryText;
@property(nonatomic, strong) NSString * originalTitle;
@property(nonatomic, strong) NSString * originalMessage;
@end

@interface UIView (associatedObject)
@property(nonatomic, strong) NSString * originalTitle;
@property(nonatomic, strong) NSString * originalMessage;
@end


NCNotificationListCollectionView *notificationList = nil;

static BOOL enabled;
static BOOL messageEnabled;
static NSString *censorText;
static BOOL locked = YES;

static void loadPrefs(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
	NSMutableDictionary *prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:[NSHomeDirectory() stringByAppendingFormat:@"/Library/Preferences/%s.plist", "com.xcxiao.hideSender"]];

	enabled = prefs[@"enabled"] ? [prefs[@"enabled"] boolValue] : YES;
	messageEnabled = prefs[@"messageEnabled"] ? [prefs[@"messageEnabled"] boolValue] : NO;
	censorText = prefs[@"censorText"] && !([prefs[@"censorText"] isEqualToString:@""]) ? [prefs[@"censorText"] stringValue] : @"Protected by HideSender";

	[prefs release];
}

%hook NCNotificationContentView

%property(nonatomic, strong) NSString * originalTitle;
%property(nonatomic, strong) NSString * originalMessage;

- (instancetype)initWithStyle:(NSInteger)arg1 {
	NCNotificationContentView *cv = %orig;
	[[NSNotificationCenter defaultCenter] addObserver:cv selector:@selector(showSender) name:@"showSender" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:cv selector:@selector(hideSender) name:@"hideSender" object:nil];
	return cv;
}

- (void)setPrimaryText:(NSString *)str {
	self.originalTitle = str;
	if(enabled && locked && str && ![str isEqualToString:@""]) %orig(censorText);
	else %orig(str);
}

%new
- (void)showSender {
	[self setPrimaryText:self.originalTitle];
}

%new
- (void)hideSender {
	if(self.originalTitle && ![self.originalTitle isEqualToString:@""]) [self setPrimaryText:censorText];
}

%end

%hook CSCoverSheetViewController

- (void)setAuthenticated:(BOOL)arg1 {
	%orig;
	locked = !arg1;
	if(enabled) {
		if(!locked) [[NSNotificationCenter defaultCenter] postNotificationName:@"showSender" object:nil userInfo:nil];
		else [[NSNotificationCenter defaultCenter] postNotificationName:@"hideSender" object:nil userInfo:nil];
	}
}

%end


%ctor {
	loadPrefs(nil, nil, nil, nil, nil);

	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
		NULL,
		(CFNotificationCallback)loadPrefs,
		CFSTR("com.xcxiao.hideSender.preferencesChanged"),
		NULL,
		CFNotificationSuspensionBehaviorDeliverImmediately
	);
}
