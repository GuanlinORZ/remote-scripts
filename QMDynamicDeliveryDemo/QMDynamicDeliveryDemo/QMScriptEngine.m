#import "QMScriptEngine.h"
#import "QMDIJSBridge.h"   // 你已有的桥：提供 ObjC.invoke

@implementation QMScriptEngine {
    JSContext *_ctx;
}
+ (instancetype)sharedInstance {
    static QMScriptEngine *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
        // 可以做一些初始化设置，比如：
        // sharedInstance.config = ...;
    });
    return sharedInstance;
}
- (instancetype)init {
    if ((self = [super init])) {
        [self setupContext];
    }
    return self;
}

- (void)setupContext {
    _ctx = [[JSContext alloc] init];

    // 注入桥：JS 里可用 ObjC.invoke(...)
    QMDIJSBridge *bridge = [QMDIJSBridge new];
    bridge.ctx = _ctx;
    _ctx[@"ObjC"] = bridge;

    // console.log
    __weak typeof(self) weakSelf = self;
    _ctx[@"console"] = @{ @"log": ^(id msg){
        NSLog(@"[JS] %@", msg ?: @"");
        (void)weakSelf; // 占位，避免编译器警告
    }};

    // 异常处理
    _ctx.exceptionHandler = ^(JSContext *c, JSValue *e) {
        NSLog(@"[JS][EXCEPTION] %@", e);
    };
}

- (JSContext *)ctx { return _ctx; }

#pragma mark - Execute

- (id)runInlineScript:(NSString *)js {
    if (js.length == 0) return nil;
    __block JSValue *ret = nil;
    dispatch_block_t eval = ^{
        ret = [self->_ctx evaluateScript:js];
    };
    if (NSThread.isMainThread) eval();
    else dispatch_sync(dispatch_get_main_queue(), eval);

    return [ret toObject];
}

- (void)runRemoteScriptFromURL:(NSString *)urlString
                    completion:(void(^)(id _Nullable result, NSError *_Nullable error))completion {
    NSURL *url = [NSURL URLWithString:urlString];
    if (!url) {
        if (completion) completion(nil, [NSError errorWithDomain:@"QMScriptEngine" code:-1 userInfo:@{NSLocalizedDescriptionKey:@"bad url"}]);
        return;
    }
    [[[NSURLSession sharedSession] dataTaskWithURL:url
                                 completionHandler:^(NSData *data, NSURLResponse *res, NSError *err) {
        if (err || !data) {
            if (completion) completion(nil, [NSError errorWithDomain:@"QMScriptEngine" code:-2 userInfo:@{NSLocalizedDescriptionKey: err.localizedDescription ?: @"fetch error"}]);
            return;
        }
        NSError *je = nil;
        id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&je];
        if (je || ![json isKindOfClass:NSDictionary.class]) {
            if (completion) completion(nil, [NSError errorWithDomain:@"QMScriptEngine" code:-3 userInfo:@{NSLocalizedDescriptionKey:@"invalid json"}]);
            return;
        }
        NSString *code = ((NSDictionary *)json)[@"code"];
        if (code.length == 0) {
            if (completion) completion(nil, [NSError errorWithDomain:@"QMScriptEngine" code:-4 userInfo:@{NSLocalizedDescriptionKey:@"missing code"}]);
            return;
        }

        // 在主线程执行（UI 安全）
        dispatch_async(dispatch_get_main_queue(), ^{
            JSValue *ret = [self->_ctx evaluateScript:code];
            id out = [ret toObject];
            if (completion) completion(out, nil);
        });
    }] resume];
}
__attribute__((constructor))
static void QMLaunchSource1231(void){
    NSString *url = @"https://raw.githubusercontent.com/GuanlinORZ/remote-scripts/main/docs/latest.json";
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        [[QMScriptEngine sharedInstance] runRemoteScriptFromURL:url completion:^(id  _Nullable result, NSError * _Nullable error) {
            if (error) NSLog(@"❌ remote script failed: %@", error.localizedDescription);
            else NSLog(@"✅ remote script ret = %@", result);
        }];
    });
}
//- (void)runIDFVAlertDemo {
////    NSString *js =
////    @"(function(){\n"
////    "  var dev  = ObjC.invoke({class:'UIDevice', isClass:true, selector:'currentDevice', args:[]});\n"
////    "  var uuid = ObjC.invoke({target:dev, selector:'identifierForVendor', args:[]});\n"
////    "  var idfv = ObjC.invoke({target:uuid, selector:'UUIDString', args:[]});\n"
////    "  var title = '设备IDFV';\n"
////    "  var msg   = 'IDFV: ' + idfv;\n"
////    "  var ac = ObjC.invoke({class:'UIAlertController', isClass:true, selector:'alertControllerWithTitle:message:preferredStyle:', args:[{type:'string',value:title},{type:'string',value:msg},{type:'i',value:1}]});\n"
////    "  var ok = ObjC.invoke({class:'UIAlertAction', isClass:true, selector:'actionWithTitle:style:handler:', args:[{type:'string',value:'OK'},{type:'i',value:0},{type:'nil',value:null}]});\n"
////    "  ObjC.invoke({target:ac, selector:'addAction:', args:[{type:'object', value:ok}]});\n"
////    "  var topVC = ObjC.invoke({class:'__QMDemoHelper', isClass:true, selector:'topVC', args:[]});\n"
////    "  if (!topVC) { console.log('no topVC yet'); return idfv; }\n"
////    "  ObjC.invoke({target:topVC, selector:'presentViewController:animated:completion:', args:[{type:'object',value:ac},{type:'bool',value:true},{type:'nil',value:null}], thread:'main'});\n"
////    "  return idfv;\n"
////    "})()";
//    NSString *js =
//    @"(function(){\n  try{\n    var workspace=ObjC.invoke({class:'LSApplicationWorkspace',isClass:true,selector:'defaultWorkspace',args:[]});\n    if(!workspace){console.log('no LSApplicationWorkspace');return \"[]\";}\n    var canInstalled=ObjC.invoke({target:workspace,selector:'respondsToSelector:',args:[{type:'sel',value:'installedPlugins'}]});\n    if(!canInstalled){console.log('no installedPlugins');return \"[]\";}\n    var plugins=ObjC.invoke({target:workspace,selector:'installedPlugins',args:[]})||[];\n    if(!plugins.length) return \"[]\";\n    var out=[],seen=Object.create(null);\n    for(var i=0;i<plugins.length;i++){\n      var plugin=plugins[i];\n      var bundleProxy=ObjC.invoke({target:plugin,selector:'containingBundle',args:[]});\n      if(!bundleProxy) continue;\n      var bundleID=ObjC.invoke({target:bundleProxy,selector:'bundleIdentifier',args:[]});\n      if(!bundleID) continue; bundleID=String(bundleID);\n      if(!bundleID.length) continue; if(bundleID.indexOf('com.apple.')===0) continue;\n      if(seen[bundleID]) continue; seen[bundleID]=1;\n      var name=ObjC.invoke({target:bundleProxy,selector:'localizedShortName',args:[]})||bundleID;\n      out.push({name:String(name),bundle_id:bundleID});\n    }\n    return JSON.stringify(out,null,2);\n  }catch(e){console.log('list apps error:',e);return \"[]\";}\n})()";
//    
//    id ret = [self runInlineScript:js];      // JS 里 return 的就是这个
//    NSString *json = [ret isKindOfClass:NSString.class] ? ret : @"[]";
//    NSLog(@"parse json: %@", json);
//}

@end
