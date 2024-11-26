//
//  SVGAVideoEntity.h
//  SVGAPlayer
//
//  Created by 崔明辉 on 16/6/17.
//  Copyright © 2016年 UED Center. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class SVGAVideoEntity, SVGAVideoSpriteEntity, SVGAVideoSpriteFrameEntity, SVGABitmapLayer, SVGAVectorLayer, SVGAAudioEntity;
@class SVGAProtoMovieEntity;

typedef NS_OPTIONS(NSUInteger, SVGAResetType) {
    SVGAResetTypeMovie = 1 << 0,
    SVGAResetTypeImg = 1 << 1,
    SVGAResetTypeSprite = 1 << 2,
    SVGAResetTypeAudio = 1 << 3,
};

@interface SVGAVideoEntity : NSObject

@property (nonatomic, readonly) CGSize videoSize;
@property (nonatomic, readonly) int FPS;
@property (nonatomic, readonly) int frames;

@property (nonatomic, readonly) NSDictionary<NSString *, UIImage *> *images;
@property (nonatomic, readonly) NSDictionary<NSString *, NSData *> *audiosData;
@property (nonatomic, readonly) NSArray<SVGAVideoSpriteEntity *> *sprites;
@property (nonatomic, readonly) NSArray<SVGAAudioEntity *> *audios;

- (instancetype)initWithSource:(id)source cacheDir:(NSString *)cacheDir;

- (void)resetType:(SVGAResetType)type withSource:(id)source;
- (void)resetSpritesWithSource:(id)source;
- (void)resetImagesWithSouce:(id)source;
- (void)resetAudiosWithSource:(id)source;

// 内存缓存读取
+ (SVGAVideoEntity *)readCache:(NSString *)cacheKey;

// NSCache缓存 没有限制
- (void)saveCache:(NSString *)cacheKey;

// NSMapTable| key:strong , value:weak
- (void)saveWeakCache:(NSString *)cacheKey;

@end


