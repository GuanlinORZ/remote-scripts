//
//  QMDynInvoke.h
//  QMDynamicDeliveryDemo
//
//  Created by 沈冠林 on 2025/9/18.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, QMDIThread) {
    QMDIThreadAutoMain,   // UI 相关自动切主线程
    QMDIThreadMain,
    QMDIThreadBackground,
};

@interface QMDIArg : NSObject
@property (nonatomic, copy) NSString *type;   // @"object"/@"string"/@"number"/@"bool"/@"sel"/@"nil"/@"url"/@"data_b64"/@"rect"/@"point"/@"size"/@"insets"
@property (nonatomic, strong) id value;       // 结构体用字典承载
+ (instancetype)arg:(NSString *)type value:(id)value;
@end

@interface QMDICallSpec : NSObject
@property (nonatomic, copy) NSString *className;     // 目标类（若 target 已给可留空）
@property (nonatomic, assign) BOOL isClass;          // YES 类方法 NO 实例方法
@property (nonatomic, strong) id target;             // 可直接传上一次返回的对象
@property (nonatomic, copy) NSString *selector;      // 选择器字符串
@property (nonatomic, copy) NSArray<QMDIArg *> *args;
@property (nonatomic, assign) QMDIThread thread;
@end

/// 返回：对象原样/基本类型装箱为 NSNumber/void→NSNull
FOUNDATION_EXPORT id _Nullable QMDIInvoke(QMDICallSpec *spec, NSError **err);

