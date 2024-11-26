//
//  SVGAAudioEntity.m
//  SVGAPlayer
//
//  Created by PonyCui on 2018/10/18.
//  Copyright © 2018年 UED Center. All rights reserved.
//

#import "SVGAAudioEntity.h"
#import "Svga.pbobjc.h"

@interface SVGAAudioEntity ()

@property (nonatomic, readwrite) NSString *audioKey;
@property (nonatomic, readwrite) NSInteger startFrame;
@property (nonatomic, readwrite) NSInteger endFrame;
@property (nonatomic, readwrite) NSInteger startTime;
@property (nonatomic, readwrite) NSInteger totalTime;

@end

@implementation SVGAAudioEntity

- (instancetype)initWithSource:(id)source {
    if (!source) return nil;
    self = [super init];
    if (self) {
        if ([source isKindOfClass:[SVGAProtoAudioEntity class]]) {
            SVGAProtoAudioEntity *protoObject = source;
            _audioKey = protoObject.audioKey;
            _startFrame = protoObject.startFrame;
            _endFrame = protoObject.endFrame;
            _startTime = protoObject.startTime;
            _totalTime = protoObject.totalTime;
        }
        else if ([source isKindOfClass:[NSDictionary class]]) {
            //暂时先这样处理
            NSDictionary *objDict = source;
            _audioKey = [objDict.allKeys containsObject:@"audioKey"]? [objDict[@"audioKey"] stringValue] : nil;
            _startFrame = [objDict.allKeys containsObject:@"startFrame"]?[objDict[@"startFrame"] integerValue]:0;
            _endFrame = [objDict.allKeys containsObject:@"endFrame"]?[objDict[@"endFrame"] integerValue]:0;
            _startTime = [objDict.allKeys containsObject:@"startTime"]?[objDict[@"startTime"] integerValue]:0;
            _totalTime = [objDict.allKeys containsObject:@"startTime"]?[objDict[@"startTime"] integerValue]:0;
        }
        else {}
        
    }
    return self;
}

@end
