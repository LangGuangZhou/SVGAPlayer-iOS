//
//  SVGAVideoSpriteEntity.m
//  SVGAPlayer
//
//  Created by 崔明辉 on 2017/2/20.
//  Copyright © 2017年 UED Center. All rights reserved.
//

#import "SVGAVideoSpriteEntity.h"
#import "SVGAVideoSpriteFrameEntity.h"
#import "SVGABitmapLayer.h"
#import "SVGAContentLayer.h"
#import "SVGAVectorLayer.h"
#import "Svga.pbobjc.h"

@implementation SVGAVideoSpriteEntity

// 暂时支持json 和proto
-(instancetype)initWithSource:(id)source {
    if (!source) return nil;
    self = [super init];
    if (self) {
        if ([source isKindOfClass:[SVGAProtoSpriteEntity class]]) {
            SVGAProtoSpriteEntity *protoObject = source;
            NSString *imageKey = protoObject.imageKey;
            NSString *matteKey = protoObject.matteKey;
            NSArray<NSDictionary *> *protoFrames = [protoObject.framesArray copy];
            if ([imageKey isKindOfClass:[NSString class]] && [protoFrames isKindOfClass:[NSArray class]]) {
                NSMutableArray<SVGAVideoSpriteFrameEntity *> *frames = [[NSMutableArray alloc] init];
                [protoFrames enumerateObjectsUsingBlock:^(id _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    if ([obj isKindOfClass:[SVGAProtoFrameEntity class]]) {
                        [frames addObject:[[SVGAVideoSpriteFrameEntity alloc] initWithProtoObject:obj]];
                    }
                }];
                _imageKey = imageKey;
                _frames = frames;
                _matteKey = matteKey;
            }
        }
        else if ([source isKindOfClass:[NSDictionary class]]) {
            NSDictionary *JSONObject = source;
            NSString *imageKey = JSONObject[@"imageKey"];
            NSString *matteKey = JSONObject[@"matteKey"];
            NSArray<NSDictionary *> *JSONFrames = JSONObject[@"frames"];
            if ([imageKey isKindOfClass:[NSString class]] && [JSONFrames isKindOfClass:[NSArray class]]) {
                NSMutableArray<SVGAVideoSpriteFrameEntity *> *frames = [[NSMutableArray alloc] init];
                [JSONFrames enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    if ([obj isKindOfClass:[NSDictionary class]]) {
                        [frames addObject:[[SVGAVideoSpriteFrameEntity alloc] initWithJSONObject:obj]];
                    }
                }];
                _imageKey = imageKey;
                _frames = frames;
                _matteKey = matteKey;
            }
        }
        else {}
    }
    return self;
}

- (SVGAContentLayer *)requestLayerWithBitmap:(UIImage *)bitmap {
    SVGAContentLayer *layer = [[SVGAContentLayer alloc] initWithFrames:self.frames];
    if (bitmap != nil) {
        layer.bitmapLayer = [[SVGABitmapLayer alloc] initWithFrames:self.frames];
        layer.bitmapLayer.contents = (__bridge id _Nullable)([bitmap CGImage]);
    }
    layer.vectorLayer = [[SVGAVectorLayer alloc] initWithFrames:self.frames];
    return layer;
}

@end
