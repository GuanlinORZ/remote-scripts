//
//  AppDelegate.m
//  QMDynamicDeliveryDemo
//
//  Created by 沈冠林 on 2025/9/17.
//

#import "AppDelegate.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    [self setupScripting];
       [self runDemoScript];
    return YES;
}


- (void)setupScripting {
    self.ctx = [[JSContext alloc] init];

    QMDIJSBridge *bridge = [QMDIJSBridge new];
    bridge.ctx = self.ctx;
    self.ctx[@"ObjC"] = bridge;

    // console.log 支持
    self.ctx[@"console"] = @{ @"log": ^(id msg){
        NSLog(@"[JS] %@", msg);
    } };

    self.ctx.exceptionHandler = ^(JSContext *c, JSValue *e){
        NSLog(@"[JS][EXCEPTION] %@", e);
    };
}

- (void)runDemoScript {
    /**
     NSString *js = @"(function(){\n"
     
         "var info = ObjC.invoke({class:'__QMDemoHelper', isClass:false, selector:'topInfo', args:[]});\n"
         "console.log(info);\n"
         "})();";
     [self.ctx evaluateScript:js];
     
     
     
     NSString *js =
     @"(function(){\n"
     "  var dev  = ObjC.invoke({class:'UIDevice', isClass:true,  selector:'currentDevice',        args:[]});\n"
     "  var uuid = ObjC.invoke({target:dev,                     selector:'identifierForVendor',  args:[]});\n"
     "  var idfv = ObjC.invoke({target:uuid,                    selector:'UUIDString',           args:[]}) || \"\";\n"
     "  console.log(idfv);\n"
     "  return idfv;\n"
     "})();";
     
     
     */
  

    NSString *js =
    @"(function(){\n"
    "  // ① dev = [UIDevice currentDevice]\n"
    "  var dev  = ObjC.invoke({class:'UIDevice', isClass:true, selector:'currentDevice', args:[]});\n"
    "  // ② uuid = dev.identifierForVendor\n"
    "  var uuid = ObjC.invoke({target:dev, selector:'identifierForVendor', args:[]});\n"
    "  // ③ idfv = [uuid UUIDString]\n"
    "  var idfv = ObjC.invoke({target:uuid, selector:'UUIDString', args:[]});\n"
    "  // ④ ac = [UIAlertController alertControllerWithTitle:message:preferredStyle:]\n"
    "  var title = '设备IDFV';\n"
    "  var msg   = 'IDFV: ' + idfv;\n"
    "  var ac = ObjC.invoke({class:'UIAlertController', isClass:true, selector:'alertControllerWithTitle:message:preferredStyle:', args:[{type:'string',value:title},{type:'string',value:msg},{type:'i',value:1}]});\n"
    "  // ⑤ ok = [UIAlertAction actionWithTitle:style:handler:]\n"
    "  var ok = ObjC.invoke({class:'UIAlertAction', isClass:true, selector:'actionWithTitle:style:handler:', args:[{type:'string',value:'OK'},{type:'i',value:0},{type:'nil',value:null}]});\n"
    "  // ⑥ [ac addAction:ok]\n"
    "  ObjC.invoke({target:ac, selector:'addAction:', args:[{type:'object', value:ok}]});\n"
    "  // ⑦ topVC = [__QMDemoHelper topVC]，present（UI 放主线程）\n"
    "  var topVC = ObjC.invoke({class:'__QMDemoHelper', isClass:true, selector:'topVC', args:[]});\n"
    "  ObjC.invoke({target:topVC, selector:'presentViewController:animated:completion:', args:[{type:'object',value:ac},{type:'bool',value:true},{type:'nil',value:null}], thread:'main'});\n"
    "  return idfv;\n"
    "})()";
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        JSValue *ret = [self.ctx evaluateScript:js];
        NSLog(@"IDFV = %@", [ret toObject]);
    });
   

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
