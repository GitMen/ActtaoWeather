//
//  WeatherApi.h
//  WeatherDemo
//
//  Created by 张鼎辉 on 15/5/6.
//  Copyright (c) 2015年 北京四海道达网络科技有限公司. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <UIKit/UIKit.h>

#define WeatherKey @"d1d19f9ef4fdac998e459ad62f0cbcbf" //需要自己申请key 申请地址:http://www.juhe.cn/docs/api/id/39

typedef enum:NSInteger{
    AddressLocationFial,//定位失败
    AddressLocationPrivacy,//需要用户打开隐私设置中的定位服务
    NetWorkFail,//网络请求失败
    WeatherRequestFail,//天气获取失败
}FailEnum;

@class WeatherObject,WeatherLocalWGS84TOGCJ02;

@protocol WeatherDelegate <NSObject>

/**
 请求失败
 */
- (void)weatherRequestFail:(FailEnum)failtype;
/**
 请求成功
 */
- (void)weatherDidSuccess:(WeatherObject *)object;

@end

@interface WeatherApi : NSObject

@property (nonatomic,strong)id<WeatherDelegate> weatherDelegate;

+ (instancetype)shareApi;

/**
 获取天气
 */
- (void)getWeatger;

@end



typedef enum:NSInteger{
    notFont,//未识别
    fine,//晴天
    cloudy,//多云
    overcast,//阴天
    shower,//阵雨
    thundershower,//雷阵雨
    thundershower_hail,//雷阵雨伴有冰雹
    sleet,//雨夹雪
    lightRain,//小雨
    moderateRain,//中雨
    heavyRain,//大雨
    cloudburst,//暴雨
    downpour,//大暴雨
    extraordinary_rainstorm,//特大暴雨
    snow_shower,//阵雪
    light_snow,//小雪
    moderate_snow,//中雪
    heavy_snow,//大雪
    heavy_snowfall,//暴雪
    fog,//雾
    freezing_rain,//冻雨
    sand_storm,//沙尘暴
    smoke,//浮尘
    blowingSand,//扬沙
    strongSandstorm,//强沙尘暴
    haze,//霾
}WeatherTyoe;
/**
 天气对象
 */
@interface WeatherObject : NSObject

@property (nonatomic,strong) NSString *temp; //当前温度
@property (nonatomic,strong) NSString *wind; //风的强度
@property (nonatomic,strong) NSString *wind_strength; //风的等级
@property (nonatomic,strong) NSString *wind_direction; //风的方向
@property (nonatomic,strong) NSString *weather; //今日天气
@property (nonatomic,strong) NSString *city; //城市
@property (nonatomic,strong) NSString *date_y; //日期
@property (nonatomic,strong) NSString *week;//星期几
@property (nonatomic,strong) NSString *dressing_advice; //穿衣建议
@property (nonatomic,strong) NSString *localName; //当前地点
@property (nonatomic,strong) NSString *street; //街道
@property (nonatomic,strong) NSString *subLocation; //地点
@property (nonatomic,assign) CLLocationCoordinate2D coordinate;//当前经纬度
@property (nonatomic,assign) WeatherTyoe weatherTyoe;//天气类型
@property (nonatomic,strong) UIImage *weatherTyoeIcon;//天气类型图标

- (instancetype)initWithDict:(NSDictionary *)dict;

@end


/**
 精确坐标转换,api内部使用
 */
@interface WeatherLocalWGS84TOGCJ02  : NSObject
+(CLLocationCoordinate2D)transformFromWGSToGCJ:(CLLocationCoordinate2D)wgsLoc;//坐标转换
+(BOOL)isLocationOutOfChina:(CLLocationCoordinate2D)location;//判断是否在中国
@end
