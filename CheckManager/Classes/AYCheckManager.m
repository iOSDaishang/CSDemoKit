//
//  AYCheckManager.m
//  AYCheckVersion
//  com.ayjkdev.AYCheckVersion
//  Created by Andy on 16/4/6.
//  Copyright © 2016年 AYJkdev. All rights reserved.
//

#import "AYCheckManager.h"
#import <StoreKit/StoreKit.h>
#define REQUEST_SUCCEED 200
#define CURRENT_VERSION [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]
#define BUNDLE_IDENTIFIER [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"]
#define SYSTEM_VERSION_8_OR_ABOVE (([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0)? (YES):(NO))
#define TRACK_ID @"TRACKID"
#define APP_LAST_VERSION @"APPLastVersion"
#define APP_RELEASE_NOTES @"APPReleaseNotes"
#define APP_TRACK_VIEW_URL @"APPTRACKVIEWURL"
#define SPECIAL_MODE_CHECK_URL @"https://itunes.apple.com/lookup?country=%@&bundleId=%@"
#define NORMAL_MODE_CHECK_URL @"https://itunes.apple.com/lookup?bundleId=%@"
#define SKIP_CURRENT_VERSION @"SKIPCURRENTVERSION"
#define SKIP_VERSION @"SKIPVERSION"
@interface AYCheckManager ()<SKStoreProductViewControllerDelegate, UIAlertViewDelegate>

@property (nonatomic, copy) NSString *nextTimeTitle;
@property (nonatomic, copy) NSString *confimTitle;
@property (nonatomic, copy) NSString *alertTitle;
@property (nonatomic, copy) NSString *skipVersionTitle;
@end

@implementation AYCheckManager

static AYCheckManager *checkManager = nil;
+ (instancetype)sharedCheckManager {
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        checkManager = [[AYCheckManager alloc] init];
        checkManager.nextTimeTitle = @"下次提示";
        checkManager.confimTitle = @"前往更新";
        checkManager.alertTitle = @"发现新版本";
        checkManager.skipVersionTitle = nil;
    });
    return checkManager;
}

- (void)checkVersion {
    
    [self checkVersionWithAlertTitle:self.alertTitle nextTimeTitle:self.nextTimeTitle];
}

- (void)checkVersionWithAlertTitle:(NSString *)alertTitle nextTimeTitle:(NSString *)nextTimeTitle
{
    [self checkVersionWithAlertTitle:self.alertTitle nextTimeTitle:nil confimTitle:self.confimTitle];
}
- (void)checkVersionWithAlertTitle:(NSString *)alertTitle nextTimeTitle:(NSString *)nextTimeTitle confimTitle:(NSString *)confimTitle {
    
    [self checkVersionWithAlertTitle:alertTitle nextTimeTitle:nextTimeTitle confimTitle:confimTitle skipVersionTitle:nil];
}

- (void)checkVersionWithAlertTitle:(NSString *)alertTitle nextTimeTitle:(NSString *)nextTimeTitle confimTitle:(NSString *)confimTitle skipVersionTitle:(NSString *)skipVersionTitle {
    
    self.alertTitle = alertTitle;
    self.nextTimeTitle = nextTimeTitle;
    self.confimTitle = confimTitle;
    self.skipVersionTitle = skipVersionTitle;
}

- (void)getInfoFromAppStore {
    
    NSURL *requestURL;
    if (self.countryAbbreviation == nil) {
        requestURL = [NSURL URLWithString:[NSString stringWithFormat:NORMAL_MODE_CHECK_URL,BUNDLE_IDENTIFIER]];
    } else {
        requestURL = [NSURL URLWithString:[NSString stringWithFormat:SPECIAL_MODE_CHECK_URL,self.countryAbbreviation,BUNDLE_IDENTIFIER]];
    }
    
    NSLog(@"%@",BUNDLE_IDENTIFIER);
    
    NSURLRequest *request = [NSURLRequest requestWithURL:requestURL];
    NSURLSession *session = [NSURLSession sharedSession];

    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        
        NSHTTPURLResponse *urlResponse = (NSHTTPURLResponse *)response;
        
        if (urlResponse.statusCode == REQUEST_SUCCEED) {
            NSDictionary *responseDic = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
            NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
            
            if ([responseDic[@"resultCount"] intValue] == 1) {
                
                NSArray *results = responseDic[@"results"];
                NSDictionary *resultDic = [results firstObject];
                [userDefault setObject:resultDic[@"version"] forKey:APP_LAST_VERSION];
                [userDefault setObject:resultDic[@"releaseNotes"] forKey:APP_RELEASE_NOTES];
                [userDefault setObject:resultDic[@"trackViewUrl"] forKey:APP_TRACK_VIEW_URL];
                [userDefault setObject:[resultDic[@"trackId"] stringValue] forKey:TRACK_ID];

                NSString *releaseNoteStr = resultDic[@"releaseNotes"];
                if ([releaseNoteStr containsString:@"1."])
                {
                    self.mustUpdate = YES;
                }
                else
                {
                    self.mustUpdate = NO;
                }

                NSLog(@"%@--%@",[self afterDayAlert],[userDefault objectForKey:@"dayRecord"]);

                if ([resultDic[@"version"] isEqualToString:CURRENT_VERSION] || ![[userDefault objectForKey:SKIP_VERSION] isEqualToString:resultDic[@"version"]]||![[self afterDayAlert] isEqualToString:[userDefault objectForKey:@"dayRecord"]]) {
                    
                    [userDefault setObject:[self afterDayAlert] forKey:@"dayRecord"];
                    
                    [userDefault setBool:NO forKey:SKIP_CURRENT_VERSION];
                }
                if (self.debugEnable) {
                    NSLog(@"%@   %@",[userDefault objectForKey:APP_LAST_VERSION],[userDefault objectForKey:APP_RELEASE_NOTES]);
                }

                NSLog(@"%@",[userDefault objectForKey:@"dayRecord"]);

                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    if (![[userDefault objectForKey:SKIP_CURRENT_VERSION] boolValue]) {
                        if ([self floatForVersion:resultDic[@"version"]] > [self floatForVersion:CURRENT_VERSION]) {
                            [self compareWithCurrentVersion];
                        }
                    }
                });
            }
        }
    }];
    [dataTask resume];
}
-(NSString*)afterDayAlert{

    NSDate *  senddate=[NSDate date];
    NSCalendar  *calendar=[NSCalendar  currentCalendar];
    NSUInteger  unitFlags= NSCalendarUnitDay ;
    NSDateComponents * component= [calendar components:unitFlags fromDate:senddate];
    NSInteger day = [component day];
    return [NSString stringWithFormat:@"%zd",day];
}

- (double)floatForVersion:(NSString *)version {
    NSArray *versionArray = [version componentsSeparatedByString:@"."];
    NSMutableString *versionString = @"".mutableCopy;
    for (int i = 0; i < versionArray.count; i++) {
        [versionString appendString:versionArray[i]];
        if (!i) {
            [versionString appendString:@"."];
        }
    }
    return versionString.doubleValue;
}

- (void)compareWithCurrentVersion {
    
    NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
    NSString *updateMessage = [userDefault objectForKey:APP_RELEASE_NOTES];
    if (![[userDefault objectForKey:APP_LAST_VERSION] isEqualToString:CURRENT_VERSION]) {
        if (SYSTEM_VERSION_8_OR_ABOVE) {
            __weak typeof(self) weakSelf = self;
            UIAlertController *alertControler = [UIAlertController alertControllerWithTitle:self.alertTitle message:updateMessage preferredStyle:UIAlertControllerStyleAlert];
            if (!self.mustUpdate)
            {

                UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:self.nextTimeTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {

                }];
                [alertControler addAction:cancelAction];
            }

            UIAlertAction *confimAction = [UIAlertAction actionWithTitle:self.confimTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                
                [weakSelf openAPPStore];
            }];
            [alertControler addAction:confimAction];

            if (self.skipVersionTitle != nil) {
                UIAlertAction *skipVersionAction = [UIAlertAction actionWithTitle:self.skipVersionTitle style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                    
                    [userDefault setBool:YES forKey:SKIP_CURRENT_VERSION];
                    [userDefault setObject:[userDefault objectForKey:APP_LAST_VERSION] forKey:SKIP_VERSION];
                }];
                [alertControler addAction:skipVersionAction];
            }
            [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alertControler animated:YES completion:^{
                
            }];
        } else {
            
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:self.alertTitle message:updateMessage delegate:self cancelButtonTitle:self.nextTimeTitle otherButtonTitles:self.confimTitle, self.skipVersionTitle,nil];
            [alertView show];
        }
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {

    if (self.mustUpdate)
    {
        [self openAPPStore];
    }
    else
    {
        if (buttonIndex == 0) {

        } else {

            [self openAPPStore];
        }
    }

}

- (void)openAPPStore {
    
    NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
    if (!self.openAPPStoreInsideAPP) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[userDefault objectForKey:APP_TRACK_VIEW_URL]]];
    } else {
        SKStoreProductViewController *storeViewController = [[SKStoreProductViewController alloc] init];
        storeViewController.delegate = self;
        
        NSDictionary *parametersDic = @{SKStoreProductParameterITunesItemIdentifier:[userDefault objectForKey:TRACK_ID]};
        [storeViewController loadProductWithParameters:parametersDic completionBlock:^(BOOL result, NSError * _Nullable error) {
            
            if (result) {
                [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:storeViewController animated:YES completion:^{
                    
                }];
            }
        }];
    }
    
}

- (void)productViewControllerDidFinish:(SKStoreProductViewController *)viewController {
    
    [[UIApplication sharedApplication].keyWindow.rootViewController dismissViewControllerAnimated:YES completion:^{
        
        
    }];
}

@end
