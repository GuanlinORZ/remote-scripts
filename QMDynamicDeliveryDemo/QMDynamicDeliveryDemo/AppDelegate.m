//
//  AppDelegate.m
//  QMDynamicDeliveryDemo
//
//  Created by 沈冠林 on 2025/9/17.
//

#import "AppDelegate.h"
#import "QMScriptEngine.h"
@interface AppDelegate ()
@property (nonatomic, strong) QMScriptEngine *scriptEngine;
@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.scriptEngine = [[QMScriptEngine alloc] init];

    // 1) 远程执行（你确认可用的 RAW 链接）
    NSString *url = @"https://raw.githubusercontent.com/GuanlinORZ/remote-scripts/main/docs/latest.json";
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        [self.scriptEngine runRemoteScriptFromURL:url completion:^(id  _Nullable result, NSError * _Nullable error) {
            if (error) NSLog(@"❌ remote script failed: %@", error.localizedDescription);
            else NSLog(@"✅ remote script ret = %@", result);
        }];
    });

    // 2) 或：本地演示
    // [self.scriptEngine runIDFVAlertDemo];

    return YES;
}


#pragma mark - UISceneSession lifecycle


- (UISceneConfiguration *)application:(UIApplication *)application configurationForConnectingSceneSession:(UISceneSession *)connectingSceneSession options:(UISceneConnectionOptions *)options {
    // Called when a new scene session is being created.
    // Use this method to select a configuration to create the new scene with.
    return [[UISceneConfiguration alloc] initWithName:@"Default Configuration" sessionRole:connectingSceneSession.role];
}


- (void)application:(UIApplication *)application didDiscardSceneSessions:(NSSet<UISceneSession *> *)sceneSessions {
    // Called when the user discards a scene session.
    // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
    // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
}


@end
