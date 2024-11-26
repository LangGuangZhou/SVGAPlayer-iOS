//
//  SVGAVideoEntity.m
//  SVGAPlayer
//
//  Created by 崔明辉 on 16/6/17.
//  Copyright © 2016年 UED Center. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "SVGAVideoEntity.h"
#import "SVGABezierPath.h"
#import "SVGAVideoSpriteEntity.h"
#import "SVGAAudioEntity.h"
#import "Svga.pbobjc.h"

#define MP3_MAGIC_NUMBER "ID3"

@interface SVGAVideoEntity ()

//处理视频的时候
@property (nonatomic, assign) CGSize videoSize;
@property (nonatomic, assign) int FPS;
@property (nonatomic, assign) int frames;

// 设置图片的时候
@property (nonatomic, copy) NSDictionary<NSString *, UIImage *> *images;
@property (nonatomic, copy) NSDictionary<NSString *, NSData *> *audiosData;

// spirites的时候
@property (nonatomic, copy) NSArray<SVGAVideoSpriteEntity *> *sprites;

// 处理audio的时候
@property (nonatomic, copy) NSArray<SVGAAudioEntity *> *audios;

@property (nonatomic, copy) NSString *cacheDir;

@end

@implementation SVGAVideoEntity

static NSCache *videoCache;
static NSMapTable * weakCache;
static dispatch_semaphore_t videoSemaphore;

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        videoCache = [[NSCache alloc] init];
        weakCache = [[NSMapTable alloc] initWithKeyOptions:NSPointerFunctionsStrongMemory
                                              valueOptions:NSPointerFunctionsWeakMemory
                                                  capacity:64];
        videoSemaphore = dispatch_semaphore_create(1);
    });
}

- (instancetype)initWithSource:(id)source cacheDir:(NSString *)cacheDir {
    self = [super init];
    if (self) {
        _videoSize = CGSizeMake(100, 100);
        _FPS = 20;
        _images = @{};
        _cacheDir = cacheDir;
        [self resetMovieWithSource:source];
    }
    return self;
}

- (void)resetType:(SVGAResetType)type withSource:(id)source {
    if (type <= 0) return;
    if (type & SVGAResetTypeAudio) {
        [self resetAudiosWithSource:source];
    }
    if(type & SVGAResetTypeSprite) {
        [self resetSpritesWithSource:source];
    }
    if (type & SVGAResetTypeImg) {
        [self resetImagesWithSouce:source];
    }
    if (type & SVGAResetTypeMovie) {
        [self resetMovieWithSource:source];
    }
}

- (void)resetMovieWithSource:(id)source {
    if ([source isKindOfClass:[SVGAProtoMovieEntity class]]) {
        SVGAProtoMovieEntity *protoObject = source;
        if (protoObject.hasParams) {
            self.videoSize = CGSizeMake((CGFloat)protoObject.params.viewBoxWidth, (CGFloat)protoObject.params.viewBoxHeight);
            self.FPS = (int)protoObject.params.fps;
            self.frames = (int)protoObject.params.frames;
        }
    }
    else if ([source isKindOfClass:[NSDictionary class]]) {
        NSDictionary *JSONObject = source;
        NSDictionary *movieObject = JSONObject[@"movie"];
        if ([movieObject isKindOfClass:[NSDictionary class]]) {
            NSDictionary *viewBox = movieObject[@"viewBox"];
            if ([viewBox isKindOfClass:[NSDictionary class]]) {
                NSNumber *width = viewBox[@"width"];
                NSNumber *height = viewBox[@"height"];
                if ([width isKindOfClass:[NSNumber class]] && [height isKindOfClass:[NSNumber class]]) {
                    _videoSize = CGSizeMake(width.floatValue, height.floatValue);
                }
            }
            NSNumber *FPS = movieObject[@"fps"];
            if ([FPS isKindOfClass:[NSNumber class]]) {
                _FPS = [FPS intValue];
            }
            NSNumber *frames = movieObject[@"frames"];
            if ([frames isKindOfClass:[NSNumber class]]) {
                _frames = [frames intValue];
            }
        }
    }
}

// 多个资源的系列化来源
- (void)resetImagesWithSouce:(id)source {
    
    if ([source isKindOfClass:[SVGAProtoMovieEntity class]]) {
        SVGAProtoMovieEntity *protoObject = source;
        NSMutableDictionary<NSString *, UIImage *> *images = [[NSMutableDictionary alloc] init];
        NSMutableDictionary<NSString *, NSData *> *audiosData = [[NSMutableDictionary alloc] init];
        NSDictionary *protoImages = [protoObject.images copy];
        for (NSString *key in protoImages) {
            NSString *fileName = [[NSString alloc] initWithData:protoImages[key] encoding:NSUTF8StringEncoding];
            if (fileName != nil) {
                NSString *filePath = [self.cacheDir stringByAppendingFormat:@"/%@.png", fileName];
                if (![[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
                    filePath = [self.cacheDir stringByAppendingFormat:@"/%@", fileName];
                }
                if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
                    NSData *imageData = [NSData dataWithContentsOfFile:filePath options:NSDataReadingMappedIfSafe error:NULL];
                    if (imageData != nil) {
                        UIImage *image = [[UIImage alloc] initWithData:imageData scale:[UIScreen mainScreen].scale];
                        if (image != nil) {
                            [images setObject:image forKey:[key stringByDeletingPathExtension]];
                        }
                    }
                }
            }
            else if ([protoImages[key] isKindOfClass:[NSData class]]) {
                if ([SVGAVideoEntity isMP3Data:protoImages[key]]) {
                    [audiosData setObject:protoImages[key] forKey:key];
                } else {
                    UIImage *image = [[UIImage alloc] initWithData:protoImages[key] scale:[UIScreen mainScreen].scale];
                    if (image != nil) {
                        [images setObject:image forKey:[key stringByDeletingPathExtension]];
                    }
                }
            }
        }
        self.images = images;
        self.audiosData = audiosData;
        
        return;
    }
    
    if ([source isKindOfClass:[NSDictionary class]]) {
        NSMutableDictionary<NSString *, UIImage *> *images = [[NSMutableDictionary alloc] init];
        NSDictionary<NSString *, NSString *> *JSONImages = source[@"images"];
        if ([JSONImages isKindOfClass:[NSDictionary class]]) {
            [JSONImages enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
                if ([obj isKindOfClass:[NSString class]]) {
                    NSString *filePath = [self.cacheDir stringByAppendingFormat:@"/%@.png", obj];
                    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
                        NSData *imageData = [NSData dataWithContentsOfFile:filePath options:NSDataReadingMappedIfSafe error:NULL];
                        if (imageData != nil) {
                            UIImage *image = [[UIImage alloc] initWithData:imageData scale:2.0];
                            if (image != nil) {
                                [images setObject:image forKey:[key stringByDeletingPathExtension]];
                            }
                        }
                    }
                }
            }];
        }
        self.images = images;
        return;
    }
    
}

+ (BOOL)isMP3Data:(NSData *)data {
    BOOL result = NO;
    if (data && [data length] >= strlen(MP3_MAGIC_NUMBER)) {
        if (!strncmp([data bytes], MP3_MAGIC_NUMBER, strlen(MP3_MAGIC_NUMBER))) {
            result = YES;
        }
    }
    return result;
}

- (void)resetSpritesWithSource:(id)source {
    NSMutableArray<SVGAVideoSpriteEntity *> *sprites = [[NSMutableArray alloc] init];
    NSArray *sourceSprites;
    if ([source isKindOfClass:[SVGAProtoMovieEntity class]]) {
        sourceSprites = [((SVGAProtoMovieEntity *)source).spritesArray copy];
    }
    else if ([source isKindOfClass:[NSDictionary class]]) {
        sourceSprites = ((NSDictionary *)source)[@"sprites"];
    }
    else {}
    
    if (sourceSprites.count <= 0) {
        return;
    }
    
    [sourceSprites enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        SVGAVideoSpriteEntity *spriteItem = [[SVGAVideoSpriteEntity alloc] initWithSource:obj];
        [sprites addObject:spriteItem];
    }];
    self.sprites = sprites;
}

- (void)resetAudiosWithSource:(id)source {
    NSMutableArray<SVGAAudioEntity *> *audios = [[NSMutableArray alloc] init];
    NSArray *sourceAudios;
    if ([source isKindOfClass:[SVGAProtoMovieEntity class]]) {
        sourceAudios = [((SVGAProtoMovieEntity *)source).spritesArray copy];
    }
    else if ([source isKindOfClass:[NSDictionary class]]) {
        sourceAudios = ((NSDictionary *)source)[@"audios"]; // 暂时定义
    }
    else {}
    
    if (sourceAudios.count <= 0) {
        return;
    }
    
    [sourceAudios enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        SVGAAudioEntity *audioItem = [[SVGAAudioEntity alloc] initWithSource:obj];
        [audios addObject:audioItem];
    }];
    self.audios = audios;
}

+ (SVGAVideoEntity *)readCache:(NSString *)cacheKey {
    dispatch_semaphore_wait(videoSemaphore, DISPATCH_TIME_FOREVER);
    SVGAVideoEntity * object = [videoCache objectForKey:cacheKey];
    if (!object) {
        object = [weakCache objectForKey:cacheKey];
    }
    dispatch_semaphore_signal(videoSemaphore);
    
    return  object;
}

- (void)saveCache:(NSString *)cacheKey {
    dispatch_semaphore_wait(videoSemaphore, DISPATCH_TIME_FOREVER);
    [videoCache setObject:self forKey:cacheKey];
    dispatch_semaphore_signal(videoSemaphore);
}

- (void)saveWeakCache:(NSString *)cacheKey {
    dispatch_semaphore_wait(videoSemaphore, DISPATCH_TIME_FOREVER);
    [weakCache setObject:self forKey:cacheKey];
    dispatch_semaphore_signal(videoSemaphore);
}

@end

@interface SVGAVideoSpriteEntity()

@property (nonatomic, copy) NSString *imageKey;
@property (nonatomic, copy) NSArray<SVGAVideoSpriteFrameEntity *> *frames;
@property (nonatomic, copy) NSString *matteKey;

@end

