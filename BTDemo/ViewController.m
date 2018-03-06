//
//  ViewController.m
//  BTDemo
//
//  Created by lotus on 2017/11/8.
//  Copyright © 2017年 李灿荣. All rights reserved.
//

#import "ViewController.h"
#import "LTSBTManager.h"
#import "LKCHeart.h"

static NSString *const cellIdentifier = @"cellIdentifier";
@interface ViewController ()<LTSBTManagerDelegate, TaiJianYiServiceDelegate, UITableViewDelegate, UITableViewDataSource>

//控件
@property (weak, nonatomic) IBOutlet UIButton *searchBtn;
@property (weak, nonatomic) IBOutlet UILabel *taiXinLabel;
@property (weak, nonatomic) IBOutlet UILabel *gongsuoLabel;
@property (weak, nonatomic) IBOutlet UITableView *deviceTableView;


//数据
@property (nonatomic, strong) NSArray *foundedDevice;
@property (nonatomic, strong) NSArray *connectedDevice;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self initData];
    
}

- (void)initData{
    [_deviceTableView registerClass:[UITableViewCell class] forCellReuseIdentifier:cellIdentifier];
    _foundedDevice = [NSArray array];
    _connectedDevice = [NSArray array];
    
    LTSBTManagerInstance.delegate = self;
    LTSBTManagerInstance.serviceDelegate = self;
    
}

- (IBAction)searchDevice:(id)sender {
    [LTSBTManagerInstance scanForServices:nil];
}

#pragma mark - delegate methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    switch (section) {
        case 0:
            return _connectedDevice.count;
            break;
        case 1:
            return _foundedDevice.count;
            break;
    }
    return 0;
}

- (nullable NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    if (section == 0) {
        return @"已连接";
    }else{
        return @"选择设备";
    }
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 2;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    cell.backgroundColor = [UIColor yellowColor];
    switch (indexPath.section) {
        case 0:
            cell.textLabel.text = [_connectedDevice[indexPath.row] name];
            break;
        case 1:
            cell.textLabel.text = [_foundedDevice[indexPath.row] name];
            break;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.section == 0) {
        //手动断开时，不使用自动连接
        LTSBTManagerInstance.isAutoConnected = NO;
        [LTSBTManagerInstance disconectPeripheral:_connectedDevice[indexPath.row]];
    }else{
       [LTSBTManagerInstance connectToPeripheral:_foundedDevice[indexPath.row]];
    }
    
}

- (void)manager:(LTSBTManager *)manager didUpdateState:(LTSBTManagerState)state{
    switch (state) {
        case LTSBTManagerStateOn:
            NSLog(@"===>11-9 bt device is on.");
            break;
        case LTSBTManagerStateOff:
            
            break;
        case LTSBTManagerStateUnauthorized:
            
            break;
        case LTSBTManagerStateOther:
            
            break;
        default:
            break;
    }
}

- (void)peripheralDidRefresh{
    _foundedDevice = LTSBTManagerInstance.foundedPeripheral;
    _connectedDevice = LTSBTManagerInstance.connectedPeripheral;
    
    [_deviceTableView reloadData];
}


- (void)taiJianYiService:(TaiJianYiService *)service didUpdateData:(LKCHeart *)cheart{
    NSLog(@"胎心率： %ld, 宫缩： %ld", cheart.rate, cheart.tocoValue);
    _taiXinLabel.text = [NSString stringWithFormat:@"胎心率: %ld", cheart.rate];
    _gongsuoLabel.text = [NSString stringWithFormat:@"宫缩: %ld", cheart.tocoValue];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end












