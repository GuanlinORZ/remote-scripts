//
//  QMDIJSBridge.h
//  QMDynamicDeliveryDemo
//
//  Created by 沈冠林 on 2025/9/18.
//

#import <Foundation/Foundation.h>
#import <JavaScriptCore/JavaScriptCore.h>
#import "QMDynInvoke.h"

@protocol QMDIJSExport <JSExport>
/// JS 用法： ObjC.invoke({ class:"UIApplication", isClass:true, selector:"sharedApplication", args:[] })
- (JSValue *)invoke:(NSDictionary *)specDict;
@end

@interface QMDIJSBridge : NSObject <QMDIJSExport>
@property (nonatomic, strong) JSContext *ctx;
@end
