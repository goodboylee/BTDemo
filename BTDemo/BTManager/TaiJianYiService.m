//
//  TaiJianYiService.m
//  BTDemo
//
//  Created by lotus on 2017/11/8.
//  Copyright © 2017年 李灿荣. All rights reserved.
//

#import "TaiJianYiService.h"
#import "LKCHeart.h"
#import "LMTPDecoder.h"


@interface TaiJianYiService()<CBPeripheralDelegate>
{
    id<TaiJianYiServiceDelegate> _peripheralDelegate;
}
@property (nonatomic, strong) CBPeripheral *servicePeripheral;
@property (nonatomic, strong) LMTPDecoder *decoder;
@end

@implementation TaiJianYiService

- (instancetype)initWithPeripheral:(CBPeripheral *)peripheral delegate:(id<TaiJianYiServiceDelegate>)delegate{
    self = [super init];
    if (self) {
        _servicePeripheral = peripheral;
        _servicePeripheral.delegate = self;
        _peripheralDelegate = delegate;
        _decoder = [LMTPDecoder shareInstance];
    }
    
    return self;
}


#pragma mark - public methods
- (void)startService{
    //TODO:u should specify the service u want to discover to save the device power(ur phone), passing nil for the argument will return all of the service of the peripheral.
    [_servicePeripheral discoverServices:nil];
}

- (void)resetService{
    //clear the pheriphel's delegate and assign to nil.
    if (_servicePeripheral) {
        _servicePeripheral.delegate = nil;
        _servicePeripheral = nil;
    }
}

#pragma mark - delegates
- (void)peripheral:(CBPeripheral *)peripheral didReadRSSI:(NSNumber *)RSSI error:(NSError *)error{
    if (error == nil) {
        NSLog(@"===> RSSI is %ld", RSSI.integerValue);
    }
}
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(nullable NSError *)error{
    
    
    for (CBService *service in peripheral.services)
    {
        //TODO:pass the specified service and character, not nil.
        NSLog(@"===>11-10 all service, peripheral name : %@, serviceUUID : %@", peripheral.name, [service.UUID UUIDString]);
        [peripheral discoverCharacteristics:nil forService:service];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(nullable NSError *)error{

    for (CBCharacteristic *characteristic in service.characteristics)
    {
        NSLog(@"===>11-10 all character, peripheral name : %@, serviceUUID : %@, characterUUID : %@", peripheral.name, [service.UUID UUIDString], [characteristic.UUID UUIDString]);
//        if ([[self CBUUIDToString:characteristic.UUID] isEqualToString:@"fff1"])
//        {
//            NSLog(@"read  characterUUID : %@", [characteristic.UUID UUIDString]);
//            //if the the value is often change, u shoud make a subscribe to it.
//            [peripheral setNotifyValue:YES forCharacteristic:characteristic];
//        }
//
//        if ([[self CBUUIDToString:characteristic.UUID] isEqualToString:@"fff2"])
//        {
//            NSLog(@"write  characterUUID : %@", [characteristic.UUID UUIDString]);
////            _writeCharacteristic = characteristic;
//        }
        
        
        if ([characteristic.UUID.UUIDString.lowercaseString isEqualToString:@"fff1"]){
            NSLog(@"read  characterUUID : %@", [characteristic.UUID UUIDString]);
            //if the the value is often change, u shoud make a subscribe to it instead of @"readValueForCharacteristic:characteristic"
            [peripheral setNotifyValue:YES forCharacteristic:characteristic];
            
            //reading the value of a characteristic using the readValueForCharacteristic: method can be effective for static values
            //[peripheral readValueForCharacteristic:characteristic];
        }else if ([characteristic.UUID.UUIDString.lowercaseString isEqualToString:@"fff2"]){
            NSLog(@"write  characterUUID : %@", [characteristic.UUID UUIDString]);
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(nullable NSError *)error{
    
    if (!characteristic) {
        return;
    }
    //if u care about more than one characteristic, handle it respectively. just subscribe to a characteristic here.
    NSData *data = characteristic.value;
    
    LKCHeart * heart =  [self.decoder startDecoderWithCharacterData:data];
    
    if (_peripheralDelegate && [_peripheralDelegate respondsToSelector:@selector(taiJianYiService:didUpdateData:)]) {
        [_peripheralDelegate taiJianYiService:self didUpdateData:heart];
    }
}

#pragma mark --BLEUtility
- (NSString *) CBUUIDToString:(CBUUID *)inUUID
{
    unsigned char i[16];
    [inUUID.data getBytes:i];
    if (inUUID.data.length == 2) {
        return [NSString stringWithFormat:@"%02hhx%02hhx",i[0],i[1]];
    }
    else {
        uint32_t g1 = ((i[0] << 24) | (i[1] << 16) | (i[2] << 8) | i[3]);
        uint16_t g2 = ((i[4] << 8) | (i[5]));
        uint16_t g3 = ((i[6] << 8) | (i[7]));
        uint16_t g4 = ((i[8] << 8) | (i[9]));
        uint16_t g5 = ((i[10] << 8) | (i[11]));
        uint32_t g6 = ((i[12] << 24) | (i[13] << 16) | (i[14] << 8) | i[15]);
        return [NSString stringWithFormat:@"%08x-%04hx-%04hx-%04hx-%04hx%08x",g1,g2,g3,g4,g5,g6];
    }
    return nil;
}

@end
















