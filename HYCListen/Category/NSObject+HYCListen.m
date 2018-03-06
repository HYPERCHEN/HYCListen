//
//  NSObject+HYCListen.m
//  HYCListen
//
//  Created by eric on 2018/3/6.
//  Copyright © 2018年 eric. All rights reserved.
//

#import "NSObject+HYCListen.h"
#import <objc/runtime.h>
#import <objc/message.h>

@implementation NSObject (HYCListen)

static NSString *hyc_Prefix = @"_hyc_listen_";
static void *hyc_isSwizzedClass = &hyc_isSwizzedClass;

#pragma mark - Public func

-(void)listen:(SEL)selector withCallBack:(MessageSendCallBack)callback{
    [self hyc_listen:selector protocol:nil withCallBack:callback];
}

-(void)listen:(SEL)selector in:(Protocol *)protocol withCallBack:(MessageSendCallBack)callback{
    [self hyc_listen:selector protocol:protocol withCallBack:callback];
}

#pragma mark - Private func

-(void)hyc_listen:(SEL)selector protocol:(Protocol *)protocol withCallBack:(MessageSendCallBack)callback{
    
    SEL newSelector = hyc_selector(selector);
    
    objc_setAssociatedObject(self, newSelector, callback, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    Class subClass = hyc_swizzeClass(self);
    
    Method originMethod = class_getInstanceMethod(subClass, selector);
    
    IMP originImp = method_getImplementation(originMethod);
    
    if (!originMethod) {
    
        if (!protocol) {
            return;
        }
        
        struct objc_method_description desc = protocol_getMethodDescription(protocol, selector, YES, YES);

        if(!desc.name){
            desc = protocol_getMethodDescription(protocol, selector, NO, YES);
        }
        
        if (desc.types) {
             class_addMethod(subClass, selector, _objc_msgForward, desc.types);
        }
    
    }
    else if (originImp != _objc_msgForward){
        
        const char *typeEncoding = method_getTypeEncoding(originMethod);
        
        class_addMethod(subClass, newSelector, originImp, typeEncoding);
        
        class_replaceMethod(subClass, selector, _objc_msgForward, typeEncoding);
    
    }
    
}

#pragma mark - Swizzle Func

static Class hyc_swizzeClass(id self){

    Class originClass = object_getClass(self);

    if ([objc_getAssociatedObject(self, hyc_isSwizzedClass) boolValue]) {
        return originClass;
    }

    Class subClass;

    if (originClass != [self class]) {

        swizzleForwardInvocation(originClass);

        swizzleResonpdToSelector(originClass);

        swizzleMethodSignature(originClass);

        subClass = originClass;

    }else{

        NSString *subClassName = [hyc_Prefix stringByAppendingString:NSStringFromClass(originClass)];

        subClass = object_getClass(NSClassFromString(subClassName));

        const char *subClassChar = subClassName.UTF8String;

        if (!subClass) {
            subClass = objc_allocateClassPair(originClass, subClassChar, 0);
        }
        
        if (!subClass) return nil;

        swizzleForwardInvocation(subClass);

        swizzleResonpdToSelector(subClass);

        swizzleMethodSignature(subClass);

        swizzleGetClass(subClass, originClass);

        objc_registerClassPair(subClass);

    }

    object_setClass(self, subClass);

    objc_setAssociatedObject(self, hyc_isSwizzedClass,[NSNumber numberWithBool:YES], OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    return subClass;

}

static void swizzleResonpdToSelector(Class clz){
    
    SEL originResponds = @selector(respondsToSelector:);
    
    Method method = class_getInstanceMethod(clz, originResponds);
    
    BOOL (*originImp)(id,SEL,SEL) = (void *)method_getImplementation(method);
    
    id swizzleImpBlock = ^(id self,SEL selector){
        
        Method method = class_getInstanceMethod(clz, selector);
        
        if (method && method_getImplementation(method) == _objc_msgForward) {
            if (objc_getAssociatedObject(self, hyc_selector(selector))) {
                return YES;
            }
        }
        
        return originImp(self,originResponds,selector);
    };
    
    class_replaceMethod(clz, originResponds, imp_implementationWithBlock(swizzleImpBlock), method_getTypeEncoding(method));
    
}


static void swizzleGetClass(Class subClass,Class originClass){
    
    SEL classSel = @selector(class);
    Method method = class_getInstanceMethod(subClass, classSel);
    
    id swizzeleImpBlock = ^(id self){
        return originClass;
    };
    
    class_replaceMethod(subClass, classSel, imp_implementationWithBlock(swizzeleImpBlock), method_getTypeEncoding(method));
    
}

static void swizzleMethodSignature(Class clz){
    
    SEL methodSignSel = @selector(methodSignatureForSelector:);
    
    Method method = class_getInstanceMethod(clz, methodSignSel);
    
    id swizzleImpBlock = ^(id self,SEL selector){
        Method method = class_getInstanceMethod(clz, selector);
        if (!method) {
            struct objc_super super = {
                self,
                class_getSuperclass(clz)
            };
            NSMethodSignature * (*superSend)(struct objc_super *,SEL,SEL) = (void *)objc_msgSendSuper;
            return superSend(&super,methodSignSel,selector);
        }
        return [NSMethodSignature signatureWithObjCTypes:method_getTypeEncoding(method)];
    };
    
    class_replaceMethod(clz, methodSignSel, imp_implementationWithBlock(swizzleImpBlock), method_getTypeEncoding(method));
    
}

static void swizzleForwardInvocation(Class clz){
    
    SEL forwardSel = @selector(forwardInvocation:);
    Method method = class_getInstanceMethod(clz, forwardSel);
    void (*originForwardImp)(id,SEL,NSInvocation *) = (void *)method_getImplementation(method);
    
    id swizzleImpBlock = ^(id self,NSInvocation *invocation){
    
        SEL hycSelector = hyc_selector(invocation.selector);
        
        MessageSendCallBack block = (MessageSendCallBack)objc_getAssociatedObject(self, hycSelector);
        
        if (!block) {
            if (originForwardImp) {
                originForwardImp(self,forwardSel,invocation);
            }else{
                [self doesNotRecognizeSelector:forwardSel];
            }
        }else{
            
            if ([self respondsToSelector:hycSelector]) {
                invocation.selector = hycSelector;
                [invocation invoke];
            }
            
            //get return value from invocation
            block(hyc_getArgumentArray(invocation));
        }
        
    };
    
    class_replaceMethod(clz, forwardSel, imp_implementationWithBlock(swizzleImpBlock), method_getTypeEncoding(method));
    
}

#pragma mark - Helper

static SEL hyc_selector(SEL selector){
    NSString *originSelStr = NSStringFromSelector(selector);
    return NSSelectorFromString([hyc_Prefix stringByAppendingString:originSelStr]);
}


static NSArray * _Nonnull hyc_getArgumentArray(NSInvocation * _Nonnull invocation) {
    NSUInteger count = invocation.methodSignature.numberOfArguments;
    NSMutableArray *arr = [NSMutableArray arrayWithCapacity:count - 2];
    for (NSUInteger i = 2; i < count; i ++)
        [arr addObject:hyc_getArgument(invocation, i)];
    return arr;
}

static id _Nonnull hyc_getArgument(NSInvocation * _Nonnull invocation, NSUInteger index) {
    const char *argumentType = [invocation.methodSignature getArgumentTypeAtIndex:index];
    
#define RETURN_VALUE(type) \
else if (strcmp(argumentType, @encode(type)) == 0) {\
type val = 0; \
[invocation getArgument:&val atIndex:index]; \
return @(val); \
}
    
    // Skip const type qualifier.
    if (argumentType[0] == 'r') {
        argumentType++;
    }
    
    if (strcmp(argumentType, @encode(id)) == 0
        || strcmp(argumentType, @encode(Class)) == 0
        || strcmp(argumentType, @encode(void (^)(void))) == 0
        ) {
        __unsafe_unretained id argument = nil;
        [invocation getArgument:&argument atIndex:index];
        return argument;
    }
    RETURN_VALUE(char)
    RETURN_VALUE(short)
    RETURN_VALUE(int)
    RETURN_VALUE(long)
    RETURN_VALUE(long long)
    RETURN_VALUE(unsigned char)
    RETURN_VALUE(unsigned short)
    RETURN_VALUE(unsigned int)
    RETURN_VALUE(unsigned long)
    RETURN_VALUE(unsigned long long)
    RETURN_VALUE(float)
    RETURN_VALUE(double)
    RETURN_VALUE(BOOL)
    RETURN_VALUE(const char *)
    else {
        NSUInteger size = 0;
        NSGetSizeAndAlignment(argumentType, &size, NULL);
        NSCParameterAssert(size > 0);
        uint8_t data[size];
        [invocation getArgument:&data atIndex:index];
        
        return [NSValue valueWithBytes:&data objCType:argumentType];
    }
}












@end
