//
//  __QMDemoHelper.m
//  QMDynamicDeliveryDemo
//
//  Created by 沈冠林 on 2025/9/18.
//

#import "__QMDemoHelper.h"
#import "QMTopmost.h"

@implementation __QMDemoHelper
+ (UIViewController *)topVC { return QMTopMostViewController(); }
- (NSDictionary *)topInfo { return QMTopViewInfo(); }
@end
