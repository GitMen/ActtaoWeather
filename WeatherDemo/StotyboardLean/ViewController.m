//
//  ViewController.m
//  StotyboardLean
//
//  Created by 张鼎辉 on 15/5/7.
//  Copyright (c) 2015年 北京四海道达网络科技有限公司. All rights reserved.
//

#import "ViewController.h"
#import "WeatherApi.h"

@interface ViewController ()<WeatherDelegate>
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UILabel *city;
@property (weak, nonatomic) IBOutlet UILabel *address;
@property (weak, nonatomic) IBOutlet UILabel *C;
@property (weak, nonatomic) IBOutlet UILabel *weather;
@property (weak, nonatomic) IBOutlet UILabel *make;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    
    [WeatherApi shareApi].weatherDelegate  = self;
    [[WeatherApi shareApi] getWeatger];
}

- (void)weatherDidSuccess:(WeatherObject *)object{
    _imageView.image = object.weatherTyoeIcon;
    _city.text = object.city;
    _address.text = [NSString stringWithFormat:@"%@%@",object.subLocation,object.localName];
    _C.text = object.temp;
    _weather.text = object.weather;
    _make.text = object.dressing_advice;
}
- (void)weatherRequestFail:(FailEnum)failtype{
    NSLog(@"123");
}

@end
