//
//  WeatherApi.m
//  WeatherDemo
//
//  Created by 张鼎辉 on 15/5/6.
//  Copyright (c) 2015年 北京四海道达网络科技有限公司. All rights reserved.
//

#import "WeatherApi.h"
#import <UIKit/UIKit.h>
static WeatherApi *api;

@interface WeatherApi()<NSURLConnectionDelegate,NSURLConnectionDataDelegate,CLLocationManagerDelegate>{
    CLLocationCoordinate2D _coordinate;
    NSString *_localName;
    NSString *_thoroughfare;
    NSString *_subLocality;
}
@property (nonatomic,strong) CLLocationManager *locationManager;
@end

@implementation WeatherApi

+ (instancetype)shareApi{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        api = [[WeatherApi alloc] init];
        api.locationManager = [[CLLocationManager alloc] init];
        api.locationManager.desiredAccuracy = kCLLocationAccuracyBest; //控制定位精度,越高耗电量越大。
        api.locationManager.distanceFilter = 100; //控制定位服务更新频率。单位是“米”
    });
    return api;
}


- (void)getWeatger{
    //开启定位
    if ([CLLocationManager locationServicesEnabled]) {
        if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0){
            [api.locationManager requestWhenInUseAuthorization];  //调用了这句,就会弹出允许框了.
        }
        api.locationManager.delegate = self;
        [_locationManager startUpdatingLocation];
    }else{
        [self.weatherDelegate weatherRequestFail:AddressLocationPrivacy];
    }
}



- (void)requestWeather{
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://v.juhe.cn/weather/geo?format=2&key=%@&lon=%f&lat=%f",WeatherKey,_coordinate.longitude,_coordinate.latitude]];
    NSURLRequest *request = [[NSURLRequest alloc]initWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:10];
    NSURLConnection *connection = [[NSURLConnection alloc]initWithRequest:request delegate:self];
        [connection start];
}

#pragma mark 网络代理
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error{
    [self.weatherDelegate weatherRequestFail:NetWorkFail];
}
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data{
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
    if (!dict) {
        [self.weatherDelegate weatherRequestFail:WeatherRequestFail];
    }else{
        long errCode = [dict[@"error_code"] longValue];
        if (errCode) {
            [self.weatherDelegate weatherRequestFail:WeatherRequestFail];
        }else{
            WeatherObject *object = [[WeatherObject alloc] initWithDict:dict[@"result"]];
            object.coordinate = _coordinate;
            object.localName = _localName;
            object.subLocation = _subLocality;
            object.street = _thoroughfare;
            if([self.weatherDelegate respondsToSelector:@selector(weatherDidSuccess:)]){
                [self.weatherDelegate weatherDidSuccess:object];
            }
        }
    }
}

#pragma mark 定位代理
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations{
    CLLocation *location = [locations firstObject];
    if (location.coordinate.latitude == 0) {
        [self.weatherDelegate weatherRequestFail:AddressLocationFial];
        return;
    }
    
    CLLocation *currentLocation = nil;
    if(![WeatherLocalWGS84TOGCJ02 isLocationOutOfChina:location.coordinate]){
        CLLocationCoordinate2D coord = [WeatherLocalWGS84TOGCJ02 transformFromWGSToGCJ:location.coordinate];
        currentLocation = [[CLLocation alloc] initWithLatitude:coord.latitude longitude:coord.longitude];
    }else{
        currentLocation = location;
    }
    
    _coordinate = currentLocation.coordinate;
    [[[CLGeocoder alloc] init] reverseGeocodeLocation:currentLocation completionHandler:^(NSArray *placemarks, NSError *error) {
        CLPlacemark *placemark = [placemarks objectAtIndex:0];
        NSDictionary *addressDict = placemark.addressDictionary;
        _localName = addressDict[@"Name"];
        _thoroughfare = addressDict[@"Thoroughfare"];
        _subLocality = addressDict[@"SubLocality"];
        [self requestWeather];
        [manager stopUpdatingLocation];
    }];
        
    
}
- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error{
    [self.weatherDelegate weatherRequestFail:AddressLocationFial];
}

@end

#pragma mark 天气对象
@implementation WeatherObject
- (instancetype)initWithDict:(NSDictionary *)dict{
    if (self = [super init]) {
        NSDictionary *sk = dict[@"sk"];
        NSDictionary *today = dict[@"today"];
        self.temp = sk[@"temp"];
        self.wind_direction = sk[@"wind_direction"];
        self.wind_strength = sk[@"wind_strength"];
        
        self.dressing_advice = today[@"dressing_advice"];
        self.wind = today[@"wind"];
        self.weather = today[@"weather"];
        self.city = today[@"city"];
        self.date_y = today[@"date_y"];
        self.week = today[@"week"];
       [self autoSetWeaterType];
    }
    return self;
}

- (void)autoSetWeaterType{
    NSString *weatherCode;
    if ([self isExitString:@"晴"]) {
        self.weatherTyoe = fine;
        weatherCode = @"00";
    }else if([self isExitString:@"多云"]){
        self.weatherTyoe = cloudy;
        weatherCode = @"01";
    }else if([self isExitString:@"阴天"]){
        self.weatherTyoe = overcast;
        weatherCode = @"02";
    }else if([self isExitString:@"阵雨"]){
        self.weatherTyoe = shower;
        weatherCode = @"03";
    }else if([self isExitString:@"雷阵雨"]){
        self.weatherTyoe = thundershower;
        weatherCode = @"04";
    }else if([self isExitString:@"雷阵雨伴有冰雹"]){
        self.weatherTyoe = thundershower_hail;
        weatherCode = @"05";
    }else if([self isExitString:@"雨夹雪"]){
        self.weatherTyoe = sleet;
        weatherCode = @"06";
    }else if([self isExitString:@"小雨"]){
        self.weatherTyoe = lightRain;
        weatherCode = @"07";
    }else if([self isExitString:@"中雨"]){
        self.weatherTyoe = moderateRain;
        weatherCode = @"08";
    }else if([self isExitString:@"大雨"]){
        self.weatherTyoe = heavyRain;
        weatherCode = @"09";
    }else if([self isExitString:@"特大暴雨"]){
        self.weatherTyoe = extraordinary_rainstorm;
        weatherCode = @"12";
    }else if([self isExitString:@"大暴雨"]){
        self.weatherTyoe = downpour;
        weatherCode = @"11";
    }else if([self isExitString:@"暴雨"]){
        self.weatherTyoe = cloudburst;
        weatherCode = @"10";
    }else if([self isExitString:@"阵雪"]){
        self.weatherTyoe = snow_shower;
        weatherCode = @"13";
    }else if([self isExitString:@"小雪"]){
        self.weatherTyoe = light_snow;
        weatherCode = @"14";
    }else if([self isExitString:@"中雪"]){
        self.weatherTyoe = moderate_snow;
        weatherCode = @"15";
    }else if([self isExitString:@"大雪"]){
        self.weatherTyoe = heavy_snow;
        weatherCode = @"16";
    }else if([self isExitString:@"暴雪"]){
        self.weatherTyoe = heavy_snowfall;
        weatherCode = @"17";
    }else if([self isExitString:@"雾"]){
        self.weatherTyoe = fog;
        weatherCode = @"18";
    }else if([self isExitString:@"冻雨"]){
        self.weatherTyoe = freezing_rain;
        weatherCode = @"19";
    }else if([self isExitString:@"强沙尘暴"]){
        self.weatherTyoe = strongSandstorm;
        weatherCode = @"31";
    }else if([self isExitString:@"浮尘"]){
        self.weatherTyoe = smoke;
        weatherCode = @"29";
    }else if([self isExitString:@"扬沙"]){
        self.weatherTyoe = blowingSand;
        weatherCode = @"30";
    }else if([self isExitString:@"沙尘暴"]){
        self.weatherTyoe = sand_storm;
        weatherCode = @"20";
    }else if([self isExitString:@"霾"]){
        self.weatherTyoe = haze;
        weatherCode = @"53";
    }else{
        self.weatherTyoe = notFont;
    }
    
    if (self.weatherTyoe != notFont) {
        self.weatherTyoeIcon = [self weatherTyoeIconWithCode:weatherCode];
    }
}

- (BOOL)isExitString:(NSString *)string{
    if ([self.weather rangeOfString:string].location != NSNotFound) {
        return YES;
    }else{
        return NO;
    }
}

- (UIImage *)weatherTyoeIconWithCode:(NSString *)code{
    NSDate *date = [NSDate new];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"HH";
    int h = [[formatter stringFromDate:date] intValue];
    if (h > 21 || h < 6) {//旁晚
        return [UIImage imageNamed:[NSString stringWithFormat:@"%@_night",code]];
    }else{
        return [UIImage imageNamed:[NSString stringWithFormat:@"%@_day",code]];
    }
}

@end


#pragma mark 坐标转换
const double a = 6378245.0;
const double ee = 0.00669342162296594323;
const double pi = 3.14159265358979324;
@implementation WeatherLocalWGS84TOGCJ02

+(CLLocationCoordinate2D)transformFromWGSToGCJ:(CLLocationCoordinate2D)wgsLoc
{
    CLLocationCoordinate2D adjustLoc;
    if([self isLocationOutOfChina:wgsLoc]){
        adjustLoc = wgsLoc;
    }else{
        double adjustLat = [self transformLatWithX:wgsLoc.longitude - 105.0 withY:wgsLoc.latitude - 35.0];
        double adjustLon = [self transformLonWithX:wgsLoc.longitude - 105.0 withY:wgsLoc.latitude - 35.0];
        double radLat = wgsLoc.latitude / 180.0 * pi;
        double magic = sin(radLat);
        magic = 1 - ee * magic * magic;
        double sqrtMagic = sqrt(magic);
        adjustLat = (adjustLat * 180.0) / ((a * (1 - ee)) / (magic * sqrtMagic) * pi);
        adjustLon = (adjustLon * 180.0) / (a / sqrtMagic * cos(radLat) * pi);
        adjustLoc.latitude = wgsLoc.latitude + adjustLat;
        adjustLoc.longitude = wgsLoc.longitude + adjustLon;
    }
    return adjustLoc;
}

//判断是不是在中国
+(BOOL)isLocationOutOfChina:(CLLocationCoordinate2D)location
{
    if (location.longitude < 72.004 || location.longitude > 137.8347 || location.latitude < 0.8293 || location.latitude > 55.8271)
        return YES;
    return NO;
}

+(double)transformLatWithX:(double)x withY:(double)y
{
    double lat = -100.0 + 2.0 * x + 3.0 * y + 0.2 * y * y + 0.1 * x * y + 0.2 * sqrt(abs(x));
    lat += (20.0 * sin(6.0 * x * pi) + 20.0 *sin(2.0 * x * pi)) * 2.0 / 3.0;
    lat += (20.0 * sin(y * pi) + 40.0 * sin(y / 3.0 * pi)) * 2.0 / 3.0;
    lat += (160.0 * sin(y / 12.0 * pi) + 320 * sin(y * pi / 30.0)) * 2.0 / 3.0;
    return lat;
}

+(double)transformLonWithX:(double)x withY:(double)y
{
    double lon = 300.0 + x + 2.0 * y + 0.1 * x * x + 0.1 * x * y + 0.1 * sqrt(abs(x));
    lon += (20.0 * sin(6.0 * x * pi) + 20.0 * sin(2.0 * x * pi)) * 2.0 / 3.0;
    lon += (20.0 * sin(x * pi) + 40.0 * sin(x / 3.0 * pi)) * 2.0 / 3.0;
    lon += (150.0 * sin(x / 12.0 * pi) + 300.0 * sin(x / 30.0 * pi)) * 2.0 / 3.0;
    return lon;
}
@end
