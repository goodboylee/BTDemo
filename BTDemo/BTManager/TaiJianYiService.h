//
//  TaiJianYiService.h
//  BTDemo
//
//  Created by lotus on 2017/11/8.
//  Copyright © 2017年 李灿荣. All rights reserved.
//

#import <Foundation/Foundation.h>

@class LKCHeart;
@protocol TaiJianYiServiceDelegate;

@interface TaiJianYiService : NSObject

- (instancetype)initWithPeripheral:(CBPeripheral *)peripheral delegate:(id<TaiJianYiServiceDelegate>)delegate;


/**
 peripheral start to discover service
 */
- (void)startService;


/**
 reset the peripheral's delegate and itself
 */
- (void)resetService;

@end


@protocol TaiJianYiServiceDelegate <NSObject>

@optional
- (void)taiJianYiService:(TaiJianYiService *)service didUpdateData:(LKCHeart *)cheart;


@end
