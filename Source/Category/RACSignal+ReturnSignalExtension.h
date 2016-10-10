//
//  RACSignal+ReturnSignalExtension.h
//  Pods
//
//  Created by 磊吴 on 16/5/13.
//
//

//#import <ReactiveCocoa/ReactiveCocoa.h>
#import <UIKit/UIKit.h>
#import <ReactiveObjC/ReactiveObjC.h>

@interface RACSignal (ReturnSignalExtension)

+ (RACSignal *)rac_return:(id)value;

@end
