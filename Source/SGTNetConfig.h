//
//  NetConfig.h
//  SGTFoundation
//
//  Created by 磊吴 on 16/1/6.
//  Copyright © 2016年 block. All rights reserved.
//

#ifndef SGTNetConfig_h
#define SGTNetConfig_h

typedef void (^UploadProgressBlock)(NSProgress * _Nonnull progress);

typedef void (^UploadFinishedBlock)(NSProgress * _Nonnull progress, NSError * _Nullable error);

// 请勿直接使用AFHTTPRequestOperation,以减少对第三方的依赖
typedef NSURLSessionDataTask SGTRequestOperation;

/*!
 *  @author block, 15-11-15 13:11:27
 *
 *  请求成功的回调
 *
 *  @param response 服务端返回的数据类型，通常是字典
 */
typedef void(^SGTResponseSuccess)(id _Nonnull response);

/*!
 *  @author block, 15-11-15 13:11:59
 *
 *  网络响应失败时的回调
 *
 *  @param error 错误信息
 */
typedef void(^SGTResponseFail)(NSError * _Nonnull error);

#endif /* NetConfig_h */
