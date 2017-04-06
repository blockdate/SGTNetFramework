//
//  SGTCacheStrategyCenter.m
//  Created by 吴磊 on 2017/3/21.
//  Copyright © 2017年 磊吴. All rights reserved.
//

#import "SGTCacheStrategyCenter.h"

@implementation SGTCacheStrategy



@end

#pragma mark -
#pragma mark Constants
#pragma mark -
//**********************************************************************************************************
//
//	Constants
//
//**********************************************************************************************************

#pragma mark -
#pragma mark Private Interface
#pragma mark -
//**********************************************************************************************************
//
//	Private Interface
@interface SGTCacheStrategyCenter(){
    
}

@property(nonatomic, copy) SGTCacheStrategy *(^mapperHandle)(NSURL* url, id params);

@end
//
//**********************************************************************************************************

@implementation SGTCacheStrategyCenter

#pragma mark -
#pragma mark Object Constructors
//**************************************************
//	Constructors
- (instancetype)init {
    self = [super init];
    if (self) {
        
    }
    return self;
}
//**************************************************

#pragma mark -
#pragma mark Private Methods
//**************************************************
//	Private Methods
//**************************************************

#pragma mark -
#pragma mark Self Public Methods
//**************************************************
//	Self Public Methods

+ (instancetype)defaultCenter {
    static SGTCacheStrategyCenter *center = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        center = [[self alloc] init];
    });
    return center;
}

- (void)setCacheStrategyMapper:(SGTCacheStrategy *(^)(NSURL* url, id params))handle {
    self.mapperHandle = handle;
}

- (SGTCacheStrategy *)strategyForURL:(NSURL *)url params:(id)params {
    if (self.mapperHandle != nil) {
        SGTCacheStrategy *strategy = self.mapperHandle(url,params);
        return strategy;
    }
    return nil;
}

//**************************************************

#pragma mark -
#pragma mark Override Public Methods
//**************************************************
//	Override Public Methods
//**************************************************

#pragma mark -
#pragma mark Properties Getter & Setter
//**************************************************
//	Properties
//**************************************************

@end
