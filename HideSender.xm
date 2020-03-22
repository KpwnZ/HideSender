#import <objc/runtime.h>
#import <libSparkAppList/SparkAppList.h>

@interface NCNotificationListCollectionView : UICollectionView
@end

@interface NSNotificationRequest : NSObject
@property (nonatomic, retain) NSString *sectionIdentifier;
@end

@interface NCNotificationShortLookViewController : UIViewController
@property (nonatomic, retain) NSNotificationRequest *notificationRequest;
@end

@interface NCNotificationContentView : UIView
@property (nonatomic, retain) NSString * primaryText;
@property (nonatomic, retain) NSString * secondaryText;
@property (nonatomic, retain) UILabel *primaryLabel;
@property (nonatomic, strong) NSString * originalTitle;
@property (nonatomic, strong) NSString * originalMessage;
@property (nonatomic, assign) BOOL originalTitleOnceSet;
- (NCNotificationShortLookViewController *) currentNotificationViewController ;
- (BOOL)isAllowedToHideSender ;
@end

NCNotificationListCollectionView *notificationList = nil;

static BOOL enabled;
static BOOL messageEnabled;
static BOOL allApps;
static NSString *censorText;
static BOOL locked = YES;

static void loadPrefs(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
	NSMutableDictionary *prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:[NSHomeDirectory() stringByAppendingFormat:@"/Library/Preferences/%s.plist", "com.xcxiao.hideSender"]];

	enabled = prefs[@"enabled"] ? [prefs[@"enabled"] boolValue] : YES;
	messageEnabled = prefs[@"messageEnabled"] ? [prefs[@"messageEnabled"] boolValue] : NO;
	allApps = prefs[@"allApps"] ? [prefs[@"allApps"] boolValue] : NO;
	censorText = prefs[@"censorText"] && !([prefs[@"censorText"] isEqualToString:@""]) ? [prefs[@"censorText"] stringValue] : @"Protected by HideSender";

	[prefs release];
}

%hook NCNotificationContentView

%property(nonatomic, strong) NSString * originalTitle;
%property(nonatomic, strong) NSString * originalMessage;
%property(nonatomic, assign) BOOL originalTitleOnceSet;

- (void)didMoveToWindow {
	%orig;

	if([self isAllowedToHideSender]) {
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showNotificationSender) name:@"com.xcxiao.showNCSender" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hideNotificationSender) name:@"com.xcxiao.hideNCSender" object:nil];
	}
}

- (void)setPrimaryText:(NSString *)str {

	if(enabled && ![str isEqualToString:censorText]) {
		self.originalTitle = str;
		%orig(str);
	}
	if(enabled && !locked && ![str isEqualToString:censorText]) %orig(str);
	if((enabled && locked && [self.primaryText isEqualToString:censorText]) || str == nil || self.primaryText == nil) return;
	if(enabled && locked && ![self.primaryText isEqualToString:censorText] && [self isAllowedToHideSender] && self.originalTitle) %orig(censorText);
}

%new
-(BOOL)isAllowedToHideSender {
	NCNotificationShortLookViewController *vc = [self currentNotificationViewController];
	if(!vc) return NO;
	NSString *bundleIdentifier = vc.notificationRequest.sectionIdentifier;

	return (allApps || [SparkAppList doesIdentifier:@"com.xcxiao.hideSender" andKey:@"enabledApps" containBundleIdentifier:bundleIdentifier]);
}

%new
- (void)showNotificationSender {
	if(self.originalTitle != nil && [self isAllowedToHideSender]) [self setPrimaryText:self.originalTitle];
}

%new
- (void)hideNotificationSender {
	if(self.originalTitle) {
		[self setPrimaryText:censorText];
	}
}

%new
- (NCNotificationShortLookViewController *) currentNotificationViewController {
    UIResponder *next = [self nextResponder];
    do {
        if ([next isKindOfClass:%c(NCNotificationShortLookViewController)]) {
            return (NCNotificationShortLookViewController *)next;
        }
        next = [next nextResponder];
    } while (next != nil);
    return nil;
}

%end

%hook CSCoverSheetViewController

- (void)setAuthenticated:(BOOL)arg1 {
	%orig;
	locked = !arg1;
	if(enabled) {
		if(!locked) [[NSNotificationCenter defaultCenter] postNotificationName:@"com.xcxiao.showNCSender" object:nil userInfo:nil];
		else [[NSNotificationCenter defaultCenter] postNotificationName:@"com.xcxiao.hideNCSender" object:nil userInfo:nil];
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
