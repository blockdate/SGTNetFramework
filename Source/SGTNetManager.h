//
//  SGTNetworking.h
//  YiDang-OC
//
//  Created by 磊吴 on 15/11/15.
//  Copyright © 2015年 block. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "SGTNetConfig.h"

@class AFHTTPSessionManager;
typedef NS_ENUM(NSUInteger, SGTNetResponseType) {
    SGTNetResponseTypeJSON = 1, // 默认
    SGTNetResponseTypeXML  = 2, // XML
    // 特殊情况下，一转换服务器就无法识别的，默认会尝试转换成JSON，若失败则需要自己去转换
    SGTNetResponseTypeData = 3
};

typedef NS_ENUM(NSUInteger, SGTNetRequestMethod) {
    SGTNetRequestMethodPOST = 1, // GET
    SGTNetRequestMethodGET  = 2 // POST
};

typedef NS_ENUM(NSUInteger, SGTNetRequestType) {
    SGTNetRequestTypeJSON = 1, // 默认
    SGTNetRequestTypePlainText  = 2 // 普通text/html
};

typedef NS_ENUM(NSInteger, SGTNetworkStatus) {
    SGTNetworkStatusUnknown          = -1,//未知网络
    SGTNetworkStatusNotReachable     = 0,//网络无连接
    SGTNetworkStatusReachableViaWWAN = 1,//2，3，4G网络
    SGTNetworkStatusReachableViaWiFi = 2,//WIFI网络
};

@interface SGTNetManager : NSObject

/**
 @author block, 16-05-12 15:05:00
 
 @brief 网络是否可用
 
 @return 网络是否可用
 */
+ (BOOL) isNetAvaliable;

/*!
 *  @author block, 15-11-15 13:11:50
 *
 *  GET请求接口，若不指定baseurl，可传完整的url
 *
 *  @param url     接口路径，如/path/getArticleList?categoryid=1
 *  @param success 接口成功请求到数据的回调
 *  @param fail    接口请求数据失败的回调
 *
 *  @return 返回的对象中有可取消请求的API
 */
+ (SGTRequestOperation * _Nullable)getWithUrl:(NSString * _Nullable)url
                            success:(SGTResponseSuccess _Nullable)success
                               fail:(SGTResponseFail _Nullable)fail;

/*!
 *  @author block, 15-11-15 13:11:50
 *
 *  GET请求接口，若不指定baseurl，可传完整的url
 *
 *  @param url     接口路径，如/path/getArticleList
 *  @param params  接口中所需要的拼接参数，如@{"categoryid" : @(12)}
 *  @param success 接口成功请求到数据的回调
 *  @param fail    接口请求数据失败的回调
 *
 *  @return 返回的对象中有可取消请求的API
 */
+ (SGTRequestOperation * _Nullable)getWithUrl:(NSString * _Nullable)url
                             params:(id _Nullable)params
                            success:(SGTResponseSuccess _Nullable)success
                               fail:(SGTResponseFail _Nullable)fail;

+ (SGTRequestOperation * _Nullable)getWithUrl:(NSString * _Nullable)url
                           useCache:(BOOL)useCache
                       refreshCache:(BOOL)refreshCache
                            success:(SGTResponseSuccess _Nullable)success
                               fail:(SGTResponseFail _Nullable)fail;


+ (SGTRequestOperation * _Nullable)getWithUrl:(NSString * _Nullable)url
                             params:(id _Nullable)params
                           useCache:(BOOL)useCache
                       refreshCache:(BOOL)refreshCache
                            success:(SGTResponseSuccess _Nullable)success
                               fail:(SGTResponseFail _Nullable)fail;

+ (SGTRequestOperation * _Nullable)getWithUrl:(NSString * _Nullable)url
                             params:(id _Nullable)params
                            headers:(NSDictionary * _Nullable)headers
                           useCache:(BOOL)useCache
                       refreshCache:(BOOL)refreshCache
                            success:(SGTResponseSuccess _Nullable)success
                               fail:(SGTResponseFail _Nullable)fail;

+ (SGTRequestOperation * _Nullable)getWithUrl:(NSString * _Nullable)url
                             params:(id _Nullable)params
                            headers:(NSDictionary * _Nullable)headers
                           useCache:(BOOL)useCache
                       refreshCache:(BOOL)refreshCache
                           progress:(void (^ _Nonnull)(NSProgress * _Nonnull))progress
                            success:(SGTResponseSuccess _Nonnull)success
                               fail:(SGTResponseFail _Nonnull)fail;

/*!
 *  @author block, 15-11-15 13:11:50
 *
 *  POST请求接口，若不指定baseurl，可传完整的url
 *
 *  @param url     接口路径，如/path/getArticleList
 *  @param params  接口中所需的参数，如@{"categoryid" : @(12)}
 *  @param success 接口成功请求到数据的回调
 *  @param fail    接口请求数据失败的回调
 *
 *  @return 返回的对象中有可取消请求的API
 */
+ (SGTRequestOperation * _Nullable)postWithUrl:(NSString * _Nonnull)url
                              params:(id _Nullable)params
                             success:(SGTResponseSuccess _Nullable)success
                                fail:(SGTResponseFail _Nullable)fail;

+ (SGTRequestOperation * _Nullable)postWithUrl:(NSString *_Nullable)url
                              params:(id _Nullable)params
                            useCache:(BOOL)useCache
                        refreshCache:(BOOL)refreshCache
                             success:(SGTResponseSuccess _Nullable)success
                                fail:(SGTResponseFail _Nullable)fail;

+ (SGTRequestOperation * _Nullable)postWithUrl:(NSString * _Nullable)url
                              params:(id _Nullable)params
                             headers:(NSDictionary * _Nullable)headers
                            useCache:(BOOL)useCache
                        refreshCache:(BOOL)refreshCache
                             success:(SGTResponseSuccess _Nullable)success
                                fail:(SGTResponseFail _Nullable)fail;

+ (SGTRequestOperation * _Nullable)postWithUrl:(NSString * _Nullable)url
                              params:(id _Nullable)params
                             headers:(NSDictionary * _Nullable)headers
                            useCache:(BOOL)useCache
                        refreshCache:(BOOL)refreshCache
                            progress:(void (^ _Nullable)(NSProgress * _Nonnull))progress
                             success:(SGTResponseSuccess _Nullable)success
                                fail:(SGTResponseFail _Nullable)fail;

/*!
 *  @author block, 15-11-15 13:11:39
 *
 *  图片上传接口，若不指定baseurl，可传完整的url
 *
 *  @param image    图片对象
 *  @param url      上传图片的接口路径，如/path/images/
 *  @param filename 给图片起一个名字，默认为当前日期时间,格式为"yyyyMMddHHmmss"，后缀为`jpg`
 *  @param name     与指定的图片相关联的名称，这是由后端写接口的人指定的，如imagefiles
 *  @param success  上传成功的回调
 *  @param fail     上传失败的回调
 *
 *  @return 返回类型有取消请求的api
 */
+ (SGTRequestOperation * _Nullable)uploadWithImage:(UIImage * _Nonnull)image
                                     url:(NSString * _Nonnull)url
                                filename:(NSString * _Nonnull)filename
                                    name:(NSString * _Nonnull)name
                                  params:(id _Nullable)params
                           ProgressBlock:(void (^ _Nullable)(NSProgress * _Nonnull uploadProgress))block
                                 success:(SGTResponseSuccess _Nullable)success
                                    fail:(SGTResponseFail _Nullable)fail;

/*!
 *  @author block, 15-11-15 13:11:45
 *
 *  用于指定网络请求接口的基础url，如：
 *  通常在AppDelegate中启动时就设置一次就可以了。如果接口有来源
 *  于多个服务器，可以调用更新
 *
 *  @param baseUrl 网络接口的基础url
 */
+ (void)updateBaseUrl:(NSString * _Nonnull)baseUrl;

/*!
 *  @author block, 15-11-15 13:11:06
 *
 *  对外公开可获取当前所设置的网络接口基础url
 *
 *  @return 当前基础url
 */
+ (NSString * _Nullable)baseUrl;

/**
 *  @author block
 *
 *  缓存总大小
 *
 *  @return 缓存大小
 *
 *  @since 0.0.1
 */
+ (unsigned long long)totalCacheSize;

/**
 *  @author block
 *
 *  默认不会自动清除缓存，如果需要，可以设置自动清除缓存，并且需要指定上限。当指定上限>0M时，
 *  若缓存达到了上限值，则每次启动应用则尝试自动去清理缓存。
 *  @param mSize 缓存上限大小，单位为M（兆），默认为0，表示不清理
 *
 *  @since 0.0.1
 */
+ (void)autoToClearCacheWithLimitedToSize:(NSUInteger)mSize;

/**
 *  @author block
 *
 *  清空缓存
 *
 *  @since 0.0.1
 */
+ (void)clearCaches;

/*!
 *  @author block, 15-11-15 14:11:40
 *
 *  开启或关闭接口打印信息
 *
 *  @param isDebug 开发期，最好打开，默认是NO
 */
+ (void)enableInterfaceDebug:(BOOL)isDebug;

/*!
 *  @author block, 15-11-15 15:11:16
 *
 *  开启或关闭是否自动将URL使用UTF8编码，用于处理链接中有中文时无法请求的问题
 *
 *  @param shouldAutoEncode YES or NO,默认为YES
 */
+ (void)shouldAutoEncodeUrl:(BOOL)shouldAutoEncode;

/*!
 *  @author block, 15-11-16 13:11:41
 *
 *  配置公共的请求头，只调用一次即可，通常放在应用启动的时候配置就可以了
 *
 *  @param httpHeaders 只需要将与服务器商定的固定参数设置即可
 */
+ (void)configCommonHttpHeaders:(NSDictionary * _Nonnull)httpHeaders;

/**
 @author block, 16-05-12 17:05:48
 
 @brief 当前是否处于调试状态
 
 @return yes/no
 */
+ (BOOL)isDebug;

/**
 *  @author block
 *
 *  取消当前所有请求
 *
 *  @since 0.0.1
 */
+ (void)cancelAllRequest;

/**
 *  @author block
 *
 *  取消某网址的请求
 *
 *  @param url url地址，可不带host域名
 *
 *  @since 0.0.1
 */
+ (void)cancelRequestWithURL:(NSString * _Nonnull)url;

/**
 @author block, 16-05-12 17:05:07
 
 @brief 输出成功日志
 
 @param response http response
 @param url      url
 @param params   params
 */
+ (void)logWithSuccessResponse:(id _Nullable)response url:(NSString * _Nullable)url params:(NSDictionary * _Nullable)params;

/**
 @author block, 16-05-12 17:05:34
 
 @brief 输出失败日志
 
 @param error  error
 @param url    url
 @param params params
 */
+ (void)logWithFailError:(NSError * _Nonnull)error url:(NSString * _Nonnull)url params:(NSDictionary * _Nullable)params;

/**
 @author block, 16-05-12 17:05:02
 
 @brief 是否对URL编码
 
 @return yes/no
 */
+ (BOOL)shouldEncode;

/**
 @author block, 16-05-12 17:05:20
 
 @brief 对URL编码
 
 @param url URL
 
 @return 编码后的URL
 */
+ ( NSString * _Nullable )encodeUrl:( NSString * _Nullable )url;

/**
 *  快速初始化方法，非单例
 *
 *  @return instancetype
 */
//+ (instancetype) manager;

+ ( AFHTTPSessionManager * _Nonnull )sessionManager;

@end
