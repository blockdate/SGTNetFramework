//
//  RACSignal+ReturnSignalExtension.m
//  Pods
//
//  Created by 磊吴 on 16/5/13.
//
//

#import "RACSignal+ReturnSignalExtension.h"

@implementation RACSignal (ReturnSignalExtension)

+ (RACSignal *)rac_return:(id)value {
    return [RACSignal return:value];
}

@end
