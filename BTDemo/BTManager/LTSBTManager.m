//
//  LTSBTManager.m
//  BTDemo
//
//  Created by lotus on 2017/11/8.
//  Copyright © 2017年 李灿荣. All rights reserved.
//

#import "LTSBTManager.h"

static LTSBTManager *managerInstance = nil;
static NSString *const kLastPeripheralUUID = @"kLastPeripheralUUID";

@interface LTSBTManager()<CBCentralManagerDelegate>
{

}

@property (nonatomic, strong) CBCentralManager *privateCentral;
@property (nonatomic, strong) TaiJianYiService *service;
@property (nonatomic, strong) NSMutableArray <CBPeripheral *>*privateFoundedPeripheral;
@property (nonatomic, strong) NSMutableArray <CBPeripheral *>*privateConnectedPeripheral;
@property (nonatomic, copy) NSString *lastPeripheralUUID;
@end

@implementation LTSBTManager

#pragma mark - init
+ (instancetype)shareInstance{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        managerInstance = [[super allocWithZone:NULL] init];
    });
    
    return managerInstance;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone{
    return [LTSBTManager shareInstance];
}

- (id)copy{
    return [LTSBTManager shareInstance];
}

- (instancetype)init{
    self = [super init];
    if (self) {
        [self initData];
    }
    return self;
}

- (void)initData{
    _isAutoConnected = YES;
    _privateFoundedPeripheral = [NSMutableArray array];
    _privateConnectedPeripheral = [NSMutableArray array];
    
    _foundedPeripheral = [NSArray array];
    _connectedPeripheral = [NSArray array];
    
    _lastPeripheralUUID = [[NSUserDefaults standardUserDefaults] objectForKey:kLastPeripheralUUID];
    
    //TODO:default in main queue
    _privateCentral = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
}

#pragma mark - public methods

- (void)stopScanning{
    if (self.privateCentral.isScanning) {
        [self.privateCentral stopScan];
    }
}

- (void)scanForServices:(NSArray<CBUUID *> *)services{

    //TODO:pass the specified service instead of nil.
    [self.privateCentral scanForPeripheralsWithServices:services options:nil];
}

- (void)connectToPeripheral:(CBPeripheral *)peripheral{
    if (peripheral.state == CBPeripheralStateConnecting || peripheral.state == CBPeripheralStateConnected) {
        return;
    }
    
    [self.privateCentral connectPeripheral:peripheral options:nil];
}

- (void)disconectPeripheral:(CBPeripheral *)peripheral{
    [self.privateCentral cancelPeripheralConnection:peripheral];
}

#pragma mark - delegate methods
- (void)centralManagerDidUpdateState:(CBCentralManager *)central{

    switch (central.state) {
        case CBCentralManagerStatePoweredOn:
            if (self.delegate && [self.delegate respondsToSelector:@selector(manager:didUpdateState:)]) {
                [self.delegate manager:managerInstance didUpdateState:LTSBTManagerStateOn];
            }
            
            if (_lastPeripheralUUID.length) {
                CBPeripheral *lastPeripheral = [self p_lastConnectedPeripheral];
                if (lastPeripheral) {
                    
                    [self p_addPeripheralToFoundedArrayWithPeripheral:lastPeripheral];
                    if (self.delegate && [self.delegate respondsToSelector:@selector(peripheralDidRefresh)]) {
                        [self.delegate peripheralDidRefresh];
                    }
                    
                    //调用该api后，尝试连接不会超时，除非解除对peripheral的强引用或者调用cancelPeripheralConnection:，所以即使你先运行app，在打开peripheral也能自动连接. 详情见该API文档
                    [_privateCentral connectPeripheral:lastPeripheral options:nil];
                }else{
                    //Retrieve a list of peripheral devices that are currently connected to the system
                    //if u need it, then remove the comment. configuring the code on ur need.
                    /*
                    peripherals = [_privateCentral retrieveConnectedPeripheralsWithServices:nil];
                    if (peripherals.count) {
                        [self p_addPeripheralToFoundedArrayWithPeripheral:peripherals.firstObject];
                        if (self.delegate && [self.delegate respondsToSelector:@selector(peripheralDidRefresh)]) {
                            [self.delegate peripheralDidRefresh];
                        }
                        [_privateCentral connectPeripheral:peripherals.firstObject options:nil];
                    }else{
                         //in this case, u can scan the peripheral here or depend on the user interation to scan.
                    }
                     */
                }
            }
            
            break;
        case CBCentralManagerStatePoweredOff:
            if (self.delegate && [self.delegate respondsToSelector:@selector(manager:didUpdateState:)]) {
                [self.delegate manager:managerInstance didUpdateState:LTSBTManagerStateOff];
            }
            break;
        case CBCentralManagerStateUnauthorized:
            if (self.delegate && [self.delegate respondsToSelector:@selector(manager:didUpdateState:)]) {
                [self.delegate manager:managerInstance didUpdateState:LTSBTManagerStateUnauthorized];
            }
            break;
            
        default:
            if (self.delegate && [self.delegate respondsToSelector:@selector(manager:didUpdateState:)]) {
                [self.delegate manager:managerInstance didUpdateState:LTSBTManagerStateOther];
            }
            break;
    }
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *, id> *)advertisementData RSSI:(NSNumber *)RSSI{
    
    //usually just care about the peripheral that has a name
    if (peripheral.name.length) {
        
        for (CBService *service in peripheral.services) {
            NSLog(@"peripheral name : %@,  ===serviceUUID : %@",  peripheral.name, [service.UUID UUIDString]);
        }
        [self p_addPeripheralToFoundedArrayWithPeripheral:peripheral];
        if (self.delegate && [self.delegate respondsToSelector:@selector(peripheralDidRefresh)]) {
            [self.delegate peripheralDidRefresh];
        }
    }
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral{
    
    //if u care about the RSSI of a peripheral, then open the annotation. it will result in a peripheral callback "peripheral:(CBPeripheral *)peripheral didReadRSSI:(NSNumber *)RSSI error:(NSError *)error"
    //[peripheral readRSSI];
    if ([_privateFoundedPeripheral containsObject:peripheral]) {
        [_privateFoundedPeripheral removeObject:peripheral];
        _foundedPeripheral = [_privateFoundedPeripheral copy];
    }
    
    if (![_privateConnectedPeripheral containsObject:peripheral]) {
        [_privateConnectedPeripheral addObject:peripheral];
        _connectedPeripheral = [_privateConnectedPeripheral copy];
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(peripheralDidRefresh)]) {
        [self.delegate peripheralDidRefresh];
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(manager:didConnectPeripheral:)]) {
        [self.delegate manager:managerInstance didConnectPeripheral:peripheral];
    }
    
    self.service = [[TaiJianYiService alloc] initWithPeripheral:peripheral delegate:_serviceDelegate];
    [_service startService];
    
    self.lastPeripheralUUID = [peripheral.identifier UUIDString];
    [[NSUserDefaults standardUserDefaults] setValue:[peripheral.identifier UUIDString] forKey:kLastPeripheralUUID];
    
    //连接上后设置为YES，当蓝牙距离太远后自动断开，走近时自动连接
    _isAutoConnected = YES;
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(nullable NSError *)error{
    
    [_service resetService];
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(nullable NSError *)error{
    
    for (CBPeripheral *peri in _privateConnectedPeripheral) {
        if (peri == peripheral) {

            [_privateConnectedPeripheral removeObject:peri];
            _connectedPeripheral = [_privateConnectedPeripheral copy];
            
            [self p_addPeripheralToFoundedArrayWithPeripheral:peripheral];
        }
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(peripheralDidRefresh)]) {
        [self.delegate peripheralDidRefresh];
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(manager:didDisconnectPeripheral:error:)]) {
        [self.delegate manager:managerInstance didDisconnectPeripheral:peripheral error:error];
    }
    
    //重新连接，一般比如蓝牙距离太远，当再次走近时，实现 自动连接
    CBPeripheral *lastPeripheral = [self p_lastConnectedPeripheral];
    if (lastPeripheral && _isAutoConnected) {
        [_privateCentral connectPeripheral:lastPeripheral options:nil];
    }
}

#pragma mark - private methods
- (void)p_addPeripheralToFoundedArrayWithPeripheral:(CBPeripheral *)peri{
    if (![_privateFoundedPeripheral containsObject:peri]) {
        [_privateFoundedPeripheral addObject:peri];
        _foundedPeripheral = [_privateFoundedPeripheral copy];
    }
}

//get the last connected peripheral
- (CBPeripheral *)p_lastConnectedPeripheral{
    NSUUID *temp = [[NSUUID alloc] initWithUUIDString:_lastPeripheralUUID];
    //Retrieve a list of known peripherals—peripherals that you’ve discovered or connected to in the past
    NSArray *peripherals = [_privateCentral retrievePeripheralsWithIdentifiers:@[temp]];
    return peripherals.firstObject;
}

@end





















