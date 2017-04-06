//  SGTCacheStrategyCenter.h
//  Created by 吴磊 on 2017/3/21.
//  Copyright © 2017年 磊吴. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SGTCacheStrategy : NSObject

/**
 缓存有效时常
 */
@property (nonatomic, assign, readonly) NSTimeInterval cacheAvaliableTime;

@end

@interface SGTCacheStrategyCenter : NSObject


+ (instancetype)defaultCenter;

- (void)setCacheStrategyMapper:(SGTCacheStrategy *(^)(NSURL* url, id params))handle;

- (SGTCacheStrategy *)strategyForURL:(NSURL *)url params:(id)params;

@end
