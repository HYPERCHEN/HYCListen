//
//  NSObject+HYCListen.h
//  HYCListen
//
//  Created by eric on 2018/3/6.
//  Copyright © 2018年 eric. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^MessageSendCallBack) (NSArray * paramtersArray);

@interface NSObject (HYCListen)

-(void)listen:(SEL)selector withCallBack:(MessageSendCallBack)back;

-(void)listen:(SEL)selector in:(Protocol *)protocol withCallBack:(MessageSendCallBack)back;

@end
