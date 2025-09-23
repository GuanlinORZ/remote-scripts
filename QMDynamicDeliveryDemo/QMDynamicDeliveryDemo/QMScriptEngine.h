#import <Foundation/Foundation.h>
#import <JavaScriptCore/JavaScriptCore.h>

NS_ASSUME_NONNULL_BEGIN

/// 统一管理 JSContext、桥接、脚本执行（本地/远程）
@interface QMScriptEngine : NSObject

/// 只读的 JS 执行上下文（已注入 ObjC.invoke / console.log / 异常处理）
@property (nonatomic, strong, readonly) JSContext *ctx;

/// 创建并完成初始化（注入桥、日志、异常处理）
- (instancetype)init;

/// 执行一段内联 JS（立即在主线程 evaluate）
/// 返回值会转换成 OC 对象（NSString/NSNumber/NSDictionary/NSArray/NSNull/或桥接对象）
- (id _Nullable)runInlineScript:(NSString *)js;

/// 从远程 URL 拉 JSON（你的接口），取出 "code" 并执行
/// JSON 形如：{ "code": "(function(){ ... })()", ... }
- (void)runRemoteScriptFromURL:(NSString *)urlString
                    completion:(void(^_Nullable)(id _Nullable result, NSError *_Nullable error))completion;

/// 演示：弹出 IDFV Alert（就是你现在那段脚本）
- (void)runIDFVAlertDemo;

@end

NS_ASSUME_NONNULL_END
