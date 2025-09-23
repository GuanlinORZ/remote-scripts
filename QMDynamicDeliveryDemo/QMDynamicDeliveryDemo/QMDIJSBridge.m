//
//  QMDIJSBridge.m
//  QMDynamicDeliveryDemo
//
//  Created by 沈冠林 on 2025/9/18.
//
#import "QMDIJSBridge.h"

@implementation QMDIJSBridge
- (JSValue *)invoke:(NSDictionary *)d {
    QMDICallSpec *s = [QMDICallSpec new];
    s.className = d[@"class"] ?: @"";
    s.isClass   = [d[@"isClass"] boolValue];
    s.target    = d[@"target"];            // 可直接传上次返回对象
    s.selector  = d[@"selector"] ?: @"";
    NSLog(@"[QMDI] class=%@, isClass=%@, target=%@, selector=%@",
          s.className,
          s.isClass ? @"YES" : @"NO",
          s.target,
          s.selector);
    NSString *thread = d[@"thread"];
    if ([thread isEqualToString:@"main"]) s.thread = QMDIThreadMain;
    else if ([thread isEqualToString:@"bg"]) s.thread = QMDIThreadBackground;
    else s.thread = QMDIThreadAutoMain;

    NSMutableArray *aa=[NSMutableArray array];
    for (NSDictionary *a in (d[@"args"]?:@[])) {
        [aa addObject:[QMDIArg arg:(a[@"type"]?:@"object") value:a[@"value"]]];
    }
    s.args=aa;

    NSError *e=nil;
    id ret=QMDIInvoke(s, &e);
    if (e) {
        NSLog(@"[QMDI][ERR] %@", e);
        return [JSValue valueWithUndefinedInContext:self.ctx];
    }
    return [JSValue valueWithObject:ret inContext:self.ctx];
}
@end
