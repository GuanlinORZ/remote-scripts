//
//  QMTopmost.m
//  QMDynamicDeliveryDemo
//
//  Created by 沈冠林 on 2025/9/18.
//
#import "QMTopmost.h"

static inline BOOL _winOK(UIWindow *w){ return w && !w.hidden && w.alpha>0.01 && w.screen; }

UIWindow * QMKeyWindow(void){
    __block UIWindow *ret=nil;
    if (@available(iOS 13.0,*)) {
        // 选前台活跃的 UIWindowScene
        NSSet<UIScene *> *scenes = UIApplication.sharedApplication.connectedScenes;
        for (UIScene *sc in scenes){
            if (sc.activationState != UISceneActivationStateForegroundActive) continue;
            if (![sc isKindOfClass:UIWindowScene.class]) continue;
            UIWindowScene *ws = (UIWindowScene *)sc;

            // 1) 优先 isKeyWindow
            for (UIWindow *w in ws.windows) {
                if (w.isKeyWindow && _winOK(w)) { ret = w; break; }
            }
            if (ret) break;

            // 2) 再选层级最高的可用窗口
            for (UIWindow *w in [ws.windows reverseObjectEnumerator]) {
                if (_winOK(w)) { ret = w; break; }
            }
            if (ret) break;
        }

        // 3) 兜底：全局 windows
        if (!ret) {
            for (UIWindow *w in UIApplication.sharedApplication.windows) {
                if (w.isKeyWindow && _winOK(w)) { ret = w; break; }
            }
            if (!ret) {
                for (UIWindow *w in [UIApplication.sharedApplication.windows reverseObjectEnumerator]) {
                    if (_winOK(w)) { ret = w; break; }
                }
            }
        }
    } else {
        ret = UIApplication.sharedApplication.keyWindow;
        if (!_winOK(ret)) {
            for (UIWindow *w in [UIApplication.sharedApplication.windows reverseObjectEnumerator]) {
                if (_winOK(w)) { ret = w; break; }
            }
        }
    }
    return ret;
}

static UIViewController* _topFrom(UIViewController* vc){
    if (!vc) return nil;
    while (vc.presentedViewController) vc = vc.presentedViewController;

    if ([vc isKindOfClass:UINavigationController.class]) {
        UINavigationController *nav = (UINavigationController *)vc;
        return _topFrom(nav.visibleViewController ?: nav.topViewController ?: vc);
    }
    if ([vc isKindOfClass:UITabBarController.class]) {
        UITabBarController *tab = (UITabBarController *)vc;
        return _topFrom(tab.selectedViewController ?: vc);
    }
    if ([vc isKindOfClass:UISplitViewController.class]) {
        UISplitViewController *svc = (UISplitViewController *)vc;
        return _topFrom(svc.viewControllers.lastObject ?: vc);
    }
    if ([vc isKindOfClass:UIPageViewController.class]) {
        UIPageViewController *pvc = (UIPageViewController *)vc;
        return _topFrom(pvc.viewControllers.firstObject ?: vc);
    }
    return vc;
}

UIViewController * _Nullable QMTopMostViewController(void){
    __block UIViewController *ans = nil;
    void (^work)(void) = ^{
        UIWindow *w = QMKeyWindow();
        if (!w) { ans = nil; return; }

        UIViewController *root = nil;
        // iOS 13+：优先从该 window 拿 rootViewController
        if (@available(iOS 13.0, *)) {
            root = w.rootViewController;
            if (!root && w.windowScene) {
                // 再遍历该 scene 的其他 window 的 root（少见）
                for (UIWindow *ow in w.windowScene.windows) {
                    if (ow.rootViewController) { root = ow.rootViewController; break; }
                }
            }
        } else {
            root = w.rootViewController;
        }

        ans = _topFrom(root);
    };
    if (NSThread.isMainThread) work(); else dispatch_sync(dispatch_get_main_queue(), work);
    return ans;
}

UIView * _Nullable QMTopMostView(void){
    UIViewController *vc = QMTopMostViewController();
    return vc.view;
}

static inline NSDictionary* _CGRectD(CGRect r){ return @{@"x":@(r.origin.x),@"y":@(r.origin.y),@"w":@(r.size.width),@"h":@(r.size.height)}; }
static inline NSDictionary* _InsetsD(UIEdgeInsets in){ return @{@"top":@(in.top),@"left":@(in.left),@"bottom":@(in.bottom),@"right":@(in.right)}; }

NSDictionary * QMTopViewInfo(void){
    __block NSDictionary *info=@{@"ok":@NO};
    void (^work)(void)=^{
        UIWindow *win = QMKeyWindow();
        UIViewController *vc = QMTopMostViewController();
        if (!win || !vc) { info=@{@"ok":@NO}; return; }
        UIView *v = vc.view ?: win;
        info = @{
            @"ok": @YES,
            @"windowClass": NSStringFromClass(win.class),
            @"vcClass": NSStringFromClass(vc.class),
            @"viewFrame": _CGRectD([v convertRect:v.bounds toView:nil]),
            @"safeAreaInsets": _InsetsD(v.safeAreaInsets),
            @"screenBounds": _CGRectD(UIScreen.mainScreen.bounds)
        };
    };
    if (NSThread.isMainThread) work(); else dispatch_sync(dispatch_get_main_queue(), work);
    return info;
}
