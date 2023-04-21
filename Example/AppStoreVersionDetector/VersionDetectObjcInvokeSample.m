//
//  VersionDetectObjcInvokeSample.m
//  AppStoreVersionDetector_Example
//
//  Created by chenxing on 2023/2/10.
//  Copyright © 2023 chenxing. All rights reserved.
//

#import "VersionDetectObjcInvokeSample.h"

@implementation VersionDetectObjcInvokeSample

- (void)test
{
    AppStoreVersionDetector *detector = [AppStoreVersionDetector defaultDetector];
    NSComparisonResult result = [detector compareWithOnlineVersion:@"2.3.10.1"];
    NSLog(@"Comparison Result: %ld", (long)result);
    NSLog(@"HasNewVersion: %@", detector.hasNewVersion ? @"YES" : @"NO");
    
    detector.alertAllowed = YES;
    [detector onDetectWithId:@"15674646463" delayToExecute:15.0 success:^(BOOL ret, NSDictionary<NSString *,NSString *> * _Nullable response) {
        NSLog(@"ret: %d, response: %@", ret, response);
    } failure:^(NSString * _Nonnull reason) {
        NSLog(@"reason: %@", reason);
    }];
    
    UIApplication *app = UIApplication.sharedApplication;
    UIViewController *currVC = app.vd_queryCurrentController;
    UIViewController *currVC2 = [app vd_queryCurrentController:app.vd_keyWindow.rootViewController];
    NSLog(@"CurrVC: %@, currVC2: %@", currVC, currVC2);
    
    UIAlertController *alertController = [app vd_makeAlertControllerWithTitle:@"提示" message:@"\n更新说明：\n1.修复bug; \n2.优化用户体验。" alignment:NSTextAlignmentLeft font:[UIFont systemFontOfSize:13 weight:UIFontWeightRegular] cancelTitle:@"取消" cancelAction:^(NSString * _Nullable title) {
        NSLog(@"Cancel title: %@", title);
    } defaultTitle:@"确定" defaultAction:^(NSString * _Nullable title) {
        NSLog(@"Default title: %@", title);
        [AppStoreVersionDetector.defaultDetector toAppStoreWithAppId:@"15674646463"];
        //[AppStoreVersionDetector.defaultDetector openUrl:[NSURL URLWithString:@"https://www.baidu.com"] completionHandler:^(BOOL result) {}];
    }];
    [currVC presentViewController:alertController animated:YES completion:nil];
}

@end
