# HYCListen

listen methods (or protocol methods)  using isa-swizzle

## Introduction

using block to get method's parameters and in that way the developer could watch their changes when method are called.

This lightweight tool could watch over the normal method and method in protocol.

The swizzle way is similar to the KVO which is known as the isa-swizzle.

The main steps are as following:

* swizzle current class to the subclass
* add new_selector to the subclass and pointer to the origin imp
* replace the origin selector to the `_objc_msgForward`.
* replace the new_forwardInvocation Imp(block or method) with origin forwardInvocation imp.
* use the origin invocation parameter ,change the selector ,invoke and do something u want.

 
## Usage

For example:

```
    #import "NSObject+HYCListen.h"

    [self listen:@selector(tableView:didSelectRowAtIndexPath:) in:@protocol(UITableViewDelegate) withCallBack:^(NSArray *paramtersArray) {
        NSLog(@"%@",paramtersArray[0]);
    }];
    
    [self listen:@selector(clickUp:) withCallBack:^(NSArray *paramtersArray) {
        NSLog(@"%@",paramtersArray[0]);
    }];

```


