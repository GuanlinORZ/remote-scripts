//
//  QMDynInvoke.m
//  QMDynamicDeliveryDemo
//
//  Created by 沈冠林 on 2025/9/18.
//
#import "QMDynInvoke.h"
#import <objc/message.h>

@implementation QMDIArg
+ (instancetype)arg:(NSString *)type value:(id)value { QMDIArg *a=[QMDIArg new]; a.type=type?:@"object"; a.value=value; return a; }
@end
@implementation QMDICallSpec @end

static inline BOOL _isUISelector(NSString *sel) {
    static NSArray *ui; static dispatch_once_t once; dispatch_once(&once, ^{ ui=@[@"openURL", @"present", @"push", @"setNeedsLayout", @"setNeedsDisplay"];});
    for (NSString *k in ui) if ([sel containsString:k]) return YES;
    return NO;
}
static inline BOOL _encEqPrefix(const char *t, const char *enc){ return strncmp(t, enc, strlen(enc))==0; }

static id _toObj(QMDIArg *a) {
    if (!a) return nil;
    id v = a.value;
    if ([a.type isEqualToString:@"nil"]) return (id)nil;
    if ([a.type isEqualToString:@"string"]) return [v isKindOfClass:NSString.class]?v:[v description];
    if ([a.type isEqualToString:@"number"]) return [v isKindOfClass:NSNumber.class]?v:@([[v description] doubleValue]);
    if ([a.type isEqualToString:@"bool"])   return @([v boolValue]);
    if ([a.type isEqualToString:@"url"])    return [NSURL URLWithString:[v description]?:@""];
    if ([a.type isEqualToString:@"data_b64"]) return [[NSData alloc] initWithBase64EncodedString:[v description] options:0];
    return v; // object/sel/struct 字典等
}

static BOOL _setArg(NSInvocation *inv, NSInteger idx, const char *type, QMDIArg *a, NSError **err) {
    id v = _toObj(a);
    switch (type[0]) {
        case '@': { id obj=v; [inv setArgument:&obj atIndex:idx]; return YES; }
        case ':': { SEL s = NSSelectorFromString([v description]); [inv setArgument:&s atIndex:idx]; return YES; }
        case 'c': { char x=[v charValue]; [inv setArgument:&x atIndex:idx]; return YES; }
        case 'C': { unsigned char x=[v unsignedCharValue]; [inv setArgument:&x atIndex:idx]; return YES; }
        case 's': { short x=[v shortValue]; [inv setArgument:&x atIndex:idx]; return YES; }
        case 'S': { unsigned short x=[v unsignedShortValue]; [inv setArgument:&x atIndex:idx]; return YES; }
        case 'i': { int x=[v intValue]; [inv setArgument:&x atIndex:idx]; return YES; }
        case 'I': { unsigned int x=[v unsignedIntValue]; [inv setArgument:&x atIndex:idx]; return YES; }
        case 'l': { long x=[v longValue]; [inv setArgument:&x atIndex:idx]; return YES; }
        case 'L': { unsigned long x=[v unsignedLongValue]; [inv setArgument:&x atIndex:idx]; return YES; }
        case 'q': { long long x=[v longLongValue]; [inv setArgument:&x atIndex:idx]; return YES; }
        case 'Q': { unsigned long long x=[v unsignedLongLongValue]; [inv setArgument:&x atIndex:idx]; return YES; }
        case 'f': { float x=[v floatValue]; [inv setArgument:&x atIndex:idx]; return YES; }
        case 'd': { double x=[v doubleValue]; [inv setArgument:&x atIndex:idx]; return YES; }
        case 'B': { bool x=[v boolValue]; [inv setArgument:&x atIndex:idx]; return YES; }
        case '*': { const char *x=[[v description] UTF8String]; [inv setArgument:&x atIndex:idx]; return YES; }
        default: break;
    }
    // ---- 常用结构体 ----
    if (_encEqPrefix(type, @encode(CGRect))) {
        NSDictionary *d=v?:@{}; CGRect r=CGRectMake([d[@"x"] doubleValue],[d[@"y"] doubleValue],[d[@"w"] doubleValue],[d[@"h"] doubleValue]);
        [inv setArgument:&r atIndex:idx]; return YES;
    }
    if (_encEqPrefix(type, @encode(CGPoint))) {
        NSDictionary *d=v?:@{}; CGPoint p=CGPointMake([d[@"x"] doubleValue],[d[@"y"] doubleValue]);
        [inv setArgument:&p atIndex:idx]; return YES;
    }
    if (_encEqPrefix(type, @encode(CGSize))) {
        NSDictionary *d=v?:@{}; CGSize s=CGSizeMake([d[@"w"] doubleValue],[d[@"h"] doubleValue]);
        [inv setArgument:&s atIndex:idx]; return YES;
    }
    if (_encEqPrefix(type, @encode(UIEdgeInsets))) {
        NSDictionary *d=v?:@{}; UIEdgeInsets in=UIEdgeInsetsMake([d[@"top"] doubleValue],[d[@"left"] doubleValue],[d[@"bottom"] doubleValue],[d[@"right"] doubleValue]);
        [inv setArgument:&in atIndex:idx]; return YES;
    }
    if (err) *err=[NSError errorWithDomain:@"QMDI" code:-2 userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:@"Unsupported arg type: %s", type]}];
    return NO;
}

static id _getRet(NSInvocation *inv, const char *type) {
    switch (type[0]) {
        case 'v': return [NSNull null];
        case '@': { __unsafe_unretained id obj=nil; [inv getReturnValue:&obj]; return obj; }
        case ':': { SEL s=NULL; [inv getReturnValue:&s]; return s?NSStringFromSelector(s):nil; }
        case 'c': { char x=0; [inv getReturnValue:&x]; return @(x); }
        case 'C': { unsigned char x=0; [inv getReturnValue:&x]; return @(x); }
        case 's': { short x=0; [inv getReturnValue:&x]; return @(x); }
        case 'S': { unsigned short x=0; [inv getReturnValue:&x]; return @(x); }
        case 'i': { int x=0; [inv getReturnValue:&x]; return @(x); }
        case 'I': { unsigned int x=0; [inv getReturnValue:&x]; return @(x); }
        case 'l': { long x=0; [inv getReturnValue:&x]; return @(x); }
        case 'L': { unsigned long x=0; [inv getReturnValue:&x]; return @(x); }
        case 'q': { long long x=0; [inv getReturnValue:&x]; return @(x); }
        case 'Q': { unsigned long long x=0; [inv getReturnValue:&x]; return @(x); }
        case 'f': { float x=0; [inv getReturnValue:&x]; return @(x); }
        case 'd': { double x=0; [inv getReturnValue:&x]; return @(x); }
        case 'B': { bool x=false; [inv getReturnValue:&x]; return @(x); }
        default:  return nil;
    }
}
id QMDIInvoke(QMDICallSpec *spec, NSError **err) {
    // 0) 基础校验
    if (!spec.selector.length) {
        if (err) *err = [NSError errorWithDomain:@"QMDI" code:-10 userInfo:@{NSLocalizedDescriptionKey:@"selector empty"}];
        return nil;
    }

    // 1) 定位目标
    id target = spec.target;
    if (!target) {
        Class cls = NSClassFromString(spec.className);
        if (!cls) { if (err) *err=[NSError errorWithDomain:@"QMDI" code:-11 userInfo:@{NSLocalizedDescriptionKey:@"class not found"}]; return nil; }
        target = spec.isClass ? (id)cls : [[cls alloc] init];
        if (!target) { if (err) *err=[NSError errorWithDomain:@"QMDI" code:-12 userInfo:@{NSLocalizedDescriptionKey:@"alloc/init failed"}]; return nil; }
    }

    SEL sel = NSSelectorFromString(spec.selector);
    if (!sel || ![target respondsToSelector:sel]) {
        if (err) *err=[NSError errorWithDomain:@"QMDI" code:-13 userInfo:@{NSLocalizedDescriptionKey:@"target not respond to selector"}];
        return nil;
    }

    NSMethodSignature *sig = [target methodSignatureForSelector:sel];
    if (!sig) { if (err) *err=[NSError errorWithDomain:@"QMDI" code:-14 userInfo:@{NSLocalizedDescriptionKey:@"signature nil"}]; return nil; }

    __block id out = nil;
    void (^call)(void) = ^{
        @try {
            NSInvocation *inv = [NSInvocation invocationWithMethodSignature:sig];
            [inv setTarget:target];
            [inv setSelector:sel];

            NSUInteger maxArgs = MAX((int)sig.numberOfArguments - 2, 0);
            NSUInteger argc = MIN(spec.args.count, maxArgs);
            for (NSUInteger i = 0; i < argc; i++) {
                const char *t = [sig getArgumentTypeAtIndex:i+2];
                NSError *argErr = nil;
                if (!_setArg(inv, i+2, t, spec.args[i], &argErr)) {
                    // 参数不支持：中断调用，安全返回
                    if (err) *err = argErr ?: [NSError errorWithDomain:@"QMDI" code:-15 userInfo:@{NSLocalizedDescriptionKey:@"arg encode failed"}];
                    return;
                }
            }

            [inv invoke];
            out = _getRet(inv, sig.methodReturnType);
            if (err) *err = nil; // 成功
        }
        @catch (NSException *ex) {
            // 目标方法内部抛异常也不崩
            if (err) *err = [NSError errorWithDomain:@"QMDI"
                                               code:-16
                                           userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:@"invoke threw exception: %@", ex.name],
                                                      @"reason": ex.reason ?: @"",
                                                      @"selector": spec.selector ?: @""}];
            out = nil;
        }
    };

    BOOL needMain = (spec.thread == QMDIThreadMain) ||
                    (spec.thread == QMDIThreadAutoMain && _isUISelector(spec.selector));
    if (needMain && !NSThread.isMainThread) {
        dispatch_sync(dispatch_get_main_queue(), call);
    } else if (spec.thread == QMDIThreadBackground && NSThread.isMainThread) {
        dispatch_sync(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), call);
    } else {
        call();
    }

    return out; // 失败时为 nil，err 里有原因；成功时为对象/NSNumber/NSNull
}

