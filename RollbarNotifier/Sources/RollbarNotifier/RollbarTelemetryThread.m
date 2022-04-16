@import RollbarCommon;

#import "RollbarTelemetryThread.h"
#import "RollbarTelemetryOptions.h"

#import "RollbarTelemetry.h"
#import "RollbarTelemetryEvent.h"
#import "RollbarTelemetryBody.h"
#import "RollbarTelemetryManualBody.h"

static  RollbarTelemetryThread * _Nullable singleton = nil;

@implementation RollbarTelemetryThread {
    
    @private NSTimer *_timer;
    @private NSTimeInterval _collectionTimeInterval;
    @private RollbarTelemetryOptions *_telemetryOptions;
}

#pragma mark - Sigleton pattern

+ (nonnull instancetype)sharedInstance {
    
    //static RollbarMemoryStatsDescriptors *singleton = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        
        //singleton = [[[self class] alloc] initWithTarget:singleton selector:@selector(run) object:nil];
        singleton = [[self class] alloc];
        if ((singleton = [singleton initWithTarget:singleton //self
                                 selector:@selector(run)
                                   object:nil
                    ])) {
            
            singleton.name = [RollbarTelemetryThread className]; //@"RollbarTelemetryThread";
            
            singleton->_telemetryOptions = nil;
            
            singleton->_collectionTimeInterval = 0;
            
            singleton.active = NO;
        }

    });
    
    return singleton;
}

+ (BOOL)sharedInstanceExists {
    
    return (nil != singleton);
}

- (instancetype)initWithTarget:(id)target selector:(SEL)selector object:(nullable id)argument {
    
    if ((self = [super initWithTarget:target //self
                             selector:selector //@selector(run)
                               object:argument//nil
                ])) {
        
        self.name = [RollbarTelemetryThread className]; //@"RollbarTelemetryThread";
        
        self->_telemetryOptions = nil;
        
        self->_collectionTimeInterval = 0;
        
        self.active = NO;
    }
    
    return self;
}



//// Reset the worker thread that atomatically collects pre-configured telemetry events (if any):
//if (!rollbarTelemetryThread) {
//
//    if (!rollbarTelemetryThread.isCancelled) {
//
//        [rollbarTelemetryThread cancel];
//    }
//    while (!rollbarTelemetryThread.isFinished) {
//
//        [NSThread sleepForTimeInterval:0.1]; // [sec]
//    }
//    rollbarTelemetryThread = nil;
//}
//rollbarTelemetryThread = [[RollbarTelemetryThread alloc] initWithOptions: configuration.telemetry];


- (instancetype)configureWithOptions:(nonnull RollbarTelemetryOptions *)telemetryOptions {
    
//    self->_active = YES;

    self->_telemetryOptions = telemetryOptions;
    
    if (![self setupTimer]) {
        
        return self;
    }
    
    if (!self.executing) {
        
        [self start];
    }

    return self;
}

- (BOOL)setupTimer {
    
    self->_collectionTimeInterval = [RollbarTelemetryThread calculateCollectionTimeInterval:self->_telemetryOptions];
    
    if (self->_timer && self->_timer.timeInterval == self->_collectionTimeInterval) {
        
        // nothing fundamental needs reconfiguration...
        //return (nil != self->_timer);
        return !(0.0 == self->_timer.timeInterval);
    }
    
    if (self->_timer) {

        // shut down the existing timer:
        [self->_timer invalidate];
        while(self->_timer.valid) {

            //no-op...
        }
        self->_timer = nil;
    }
    
    if (0.0 == self->_collectionTimeInterval) {
        
        // nothing to collect...
        return NO;
    }
    
    self->_timer = [NSTimer timerWithTimeInterval:self->_collectionTimeInterval
                                           target:self
                                         selector:@selector(attemptCollection)
                                         userInfo:nil
                                          repeats:YES
    ];
//    NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
//    [runLoop addTimer:self->_timer forMode:NSDefaultRunLoopMode];
    
    return YES;
}

+ (NSTimeInterval)calculateCollectionTimeInterval:(nonnull RollbarTelemetryOptions *)telemetryOptions {
    
    // iterate through all the autocollection intervals existing in the telemetryOptions
    // and find the shortest one, then divide it by 10 and return the value:
    
    NSTimeInterval intervals[] = {
        telemetryOptions.memoryStatsAutocollectionInterval,
        //add all other new auto-collection intervals defined within the telemetryOptions...
    };
    
    int intervalsCount = sizeof(intervals)/sizeof(NSTimeInterval);
    switch (intervalsCount) {
        case 0:
            return 0;
        case 1:
            return intervals[0];
        default: {
            NSTimeInterval min = intervals[0];
            int i = 1;
            while (i < intervalsCount) {
                if (intervals[i] < min) {
                    min = intervals[i];
                }
                i++;
            }
            return min;
        }
    }
}

- (void)start {
    
    if (!self.active && [self setupTimer]) {
        
        
        static dispatch_once_t onceToken;
        
        dispatch_once(&onceToken, ^{
            
            [super start];
        });
    }
}

- (void)run {
    
    if (self.active) {
        
        return;
    }
    
    @autoreleasepool {
        
//        NSTimeInterval timeIntervalInSeconds = self->_collectionTimeInterval;
//        if (0.0 == timeIntervalInSeconds) {
//
//            return;
//        }
//
//        _timer = [NSTimer timerWithTimeInterval:timeIntervalInSeconds
//                                         target:self
//                                       selector:@selector(attemptCollection)
//                                       userInfo:nil
//                                        repeats:YES
//        ];
//
//        NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
//        [runLoop addTimer:_timer forMode:NSDefaultRunLoopMode];

//        if (![self setupTimer]) {
//
//            // nothing really to do...
//            return;
//        }
        
        self.active = YES;
        NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
        [runLoop addTimer:self->_timer forMode:NSDefaultRunLoopMode];
        while (self.active) {
            if (self->_timer) {
                [runLoop runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
            }
        }
        [runLoop run];
    }
}

- (void)attemptCollection {
    
    if (self.cancelled) {
        
        if (self->_timer) {
            
            [self->_timer invalidate];
            self->_timer = nil;
        }
        
        [NSThread exit];
    }
    
    @autoreleasepool {
        
        [self attemptMemoryStatsCollection];
        // add attempts of other auto-collections here...
    }
}

- (void)attemptMemoryStatsCollection {
    
//    [self collectMemoryStats];
//    return;
    
    static NSDate *nextCollection = nil;
    if (!nextCollection) {
        
        [self collectMemoryStats];
        nextCollection = [[NSDate date]
                          dateByAddingTimeInterval:self->_telemetryOptions.memoryStatsAutocollectionInterval
        ];
    }
    else if ([[NSDate date] compare:nextCollection] == NSOrderedAscending) {

        [self collectMemoryStats];
        nextCollection =
        [nextCollection dateByAddingTimeInterval:self->_telemetryOptions.memoryStatsAutocollectionInterval];
    }
}

- (void)collectMemoryStats {
    
    NSObject *memoryStats = [RollbarMemoryUtil getMemoryStats];
    
    [[RollbarTelemetry sharedInstance] recordManualEventForLevel:RollbarLevel_Info
                                                        withData:@{
                                                            @"memory_stats" : memoryStats,
                                                        }
    ];
}

@end
