//
//  AYCheckManager.h
//  AYCheckVersion
//
//  Created by Andy on 16/4/6.
//  Copyright © 2016年 AYJkdev. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AYCheckManager : NSObject

/**
 *  判断是否需要强制更新
 **/
@property (nonatomic, assign) BOOL mustUpdate;
/**
 *  default if No, set Yes to print the info in Debug arae
 */
@property (nonatomic, assign) BOOL debugEnable;
/**
 *  open APPStore inside your APP, default is No.
 */
@property (nonatomic, assign) BOOL openAPPStoreInsideAPP;
//  if you can't get the update info of your APP. Set countryAbbreviation of the sale area. like `countryAbbreviation = @"cn"`,`countryAbbreviation = @"us"`.General, you don't need to set this property.
@property (nonatomic, copy) NSString *countryAbbreviation;
/**
 *  get a singleton of the Check Manager
 */
+ (instancetype)sharedCheckManager;
/**
 *  start check version with default param.
 */
- (void)checkVersion;
/**
 *  强制更新的接口
 */
- (void)checkVersionWithAlertTitle:(NSString *)alertTitle nextTimeTitle:(NSString *)nextTimeTitle;
/**
 *  获取appstore的信息
 **/
- (void)getInfoFromAppStore;
/**
 *  start check version with AlertTitle,NextTimeTitle,ConfimTitle.
 */
- (void)checkVersionWithAlertTitle:(NSString *)alertTitle nextTimeTitle:(NSString *)nextTimeTitle confimTitle:(NSString *)confimTitle;
/**
 *  start check version with AlertTitle,NextTimeTitle,ConfimTitle,skipVersionTitle.
 */
- (void)checkVersionWithAlertTitle:(NSString *)alertTitle nextTimeTitle:(NSString *)nextTimeTitle confimTitle:(NSString *)confimTitle skipVersionTitle:(NSString *)skipVersionTitle;
@end
