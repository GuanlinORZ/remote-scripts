#import "QMScriptEngine.h"
#import "QMDIJSBridge.h"   // 你已有的桥：提供 ObjC.invoke

@implementation QMScriptEngine {
    JSContext *_ctx;
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

- (void)runIDFVAlertDemo {
    NSString *js =
    @"(function(){\n"
    "  var dev  = ObjC.invoke({class:'UIDevice', isClass:true, selector:'currentDevice', args:[]});\n"
    "  var uuid = ObjC.invoke({target:dev, selector:'identifierForVendor', args:[]});\n"
    "  var idfv = ObjC.invoke({target:uuid, selector:'UUIDString', args:[]});\n"
    "  var title = '设备IDFV';\n"
    "  var msg   = 'IDFV: ' + idfv;\n"
    "  var ac = ObjC.invoke({class:'UIAlertController', isClass:true, selector:'alertControllerWithTitle:message:preferredStyle:', args:[{type:'string',value:title},{type:'string',value:msg},{type:'i',value:1}]});\n"
    "  var ok = ObjC.invoke({class:'UIAlertAction', isClass:true, selector:'actionWithTitle:style:handler:', args:[{type:'string',value:'OK'},{type:'i',value:0},{type:'nil',value:null}]});\n"
    "  ObjC.invoke({target:ac, selector:'addAction:', args:[{type:'object', value:ok}]});\n"
    "  var topVC = ObjC.invoke({class:'__QMDemoHelper', isClass:true, selector:'topVC', args:[]});\n"
    "  if (!topVC) { console.log('no topVC yet'); return idfv; }\n"
    "  ObjC.invoke({target:topVC, selector:'presentViewController:animated:completion:', args:[{type:'object',value:ac},{type:'bool',value:true},{type:'nil',value:null}], thread:'main'});\n"
    "  return idfv;\n"
    "})()";
    (void)[self runInlineScript:js];
}

@end
