
//
//  LTSBTManager.h
//  BTDemo
//
//  Created by lotus on 2017/11/8.
//  Copyright © 2017年 李灿荣. All rights reserved.
//

//systhem
#import <Foundation/Foundation.h>


//
#import "TaiJianYiService.h"

#define LTSBTManagerInstance [LTSBTManager shareInstance]

typedef NS_ENUM(NSInteger, LTSBTManagerState){
    LTSBTManagerStateOn = 0,
    LTSBTManagerStateOff,
    LTSBTManagerStateUnauthorized,
    LTSBTManagerStateOther
};



@protocol LTSBTManagerDelegate;
@interface LTSBTManager : NSObject

//configure property

/**
 是否自动连接，默认为YES自动连接；当连接上后，该值为YES；当手动断开时，该值为NO
 */
@property (nonatomic, assign) BOOL isAutoConnected;
@property (nonatomic, assign) id<LTSBTManagerDelegate> delegate;
@property (nonatomic, assign) id<TaiJianYiServiceDelegate> serviceDelegate;

//callback data property
//the callback data property should be immutable if possible
@property (nonatomic, strong) NSArray <CBPeripheral *>*foundedPeripheral;
@property (nonatomic, strong) NSArray <CBPeripheral *>*connectedPeripheral;

+ (instancetype)shareInstance;

- (void)scanForServices:(NSArray <CBUUID *> *)services;

- (void)stopScanning;

- (void)connectToPeripheral:(CBPeripheral *)peripheral;

- (void)disconectPeripheral:(CBPeripheral *)peripheral;

@end

@protocol LTSBTManagerDelegate <NSObject>

@optional
- (void)manager:(LTSBTManager *)manager didUpdateState:(LTSBTManagerState)state;


/**
 usually to refresh the GUI
 */
- (void)peripheralDidRefresh;

- (void)manager:(LTSBTManager *)manager didDiscoverPeripheral:(CBPeripheral *)peripheral;


/**
 if u want to do extra things when connecting to a peripheral, implement it.
 */
- (void)manager:(LTSBTManager *)manager didConnectPeripheral:(CBPeripheral *)peripheral;

- (void)manager:(LTSBTManager *)manager didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error;

/**
 if u want to do extra things when disconnecting to a peripheral, implement it.
 */
- (void)manager:(LTSBTManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error;

@end








