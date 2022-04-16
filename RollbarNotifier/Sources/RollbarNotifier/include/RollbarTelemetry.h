@import Foundation;

#import "RollbarLevel.h"
#import "RollbarSource.h"
#import "RollbarTelemetryType.h"

@class RollbarTelemetryOptions;
@class RollbarTelemetryEvent;
@class RollbarTelemetryBody;
@class RollbarTelemetryLogBody;
@class RollbarTelemetryViewBody;
@class RollbarTelemetryErrorBody;
@class RollbarTelemetryNavigationBody;
@class RollbarTelemetryNetworkBody;
@class RollbarTelemetryConnectivityBody;
@class RollbarTelemetryManualBody;

#define NSLog(args...) [RollbarTelemetry NSLogReplacement:args];

/// RollbarTelemetry application wide "service" component
@interface RollbarTelemetry : NSObject

/// Shared service instance/singleton
+ (nonnull instancetype)sharedInstance;

#pragma mark - Sigleton pattern

+ (nonnull instancetype)sharedInstance;
+ (BOOL)sharedInstanceExists;

+ (instancetype)new NS_UNAVAILABLE;
+ (instancetype)allocWithZone:(struct _NSZone *)zone NS_UNAVAILABLE;
+ (instancetype)alloc NS_UNAVAILABLE;
+ (id)copyWithZone:(struct _NSZone *)zone NS_UNAVAILABLE;
+ (id)mutableCopyWithZone:(struct _NSZone *)zone NS_UNAVAILABLE;

- (instancetype)init NS_UNAVAILABLE;

- (void)dealloc NS_UNAVAILABLE;
- (id)copy NS_UNAVAILABLE;
- (id)mutableCopy NS_UNAVAILABLE;

#pragma mark - NSLog redirection

/// NSLog replacement
/// @param format NSLog entry format
+ (void)NSLogReplacement:(nonnull NSString *)format, ...;

#pragma mark - Config options

/// Configures this instance with provided options
/// @param telemetryOptions desired Telemetry options
- (instancetype)configureWithOptions:(nonnull RollbarTelemetryOptions *)telemetryOptions;

/// Telemetry collection enable/disable switch
@property (readwrite, atomic) BOOL enabled;

/// Enable/disable switch for scrubbing View inputs
@property (readwrite, atomic) BOOL scrubViewInputs;

/// Set of View inputs to scrub
@property (atomic, retain, nullable) NSMutableSet *viewInputsToScrub;

/// Sets whether or not to use replacement log.
/// @param shouldCapture YES/NO flag for the log capture
- (void)setCaptureLog:(BOOL)shouldCapture;

/// Sets max number of telemetry events to capture.
/// @param dataLimit the max total events limit
- (void)setDataLimit:(NSInteger)dataLimit;

#pragma mark - Telemetry data/event recording methods

/// Records/captures a telemetry event
/// @param event a telemetry event
- (void)recordEvent:(nonnull RollbarTelemetryEvent *)event;

/// Records/captures a telemetry event
/// @param level telemetry event level
/// @param source telemetry event source
/// @param body telemetry event body
- (void)recordEventWithLevel:(RollbarLevel)level
                      source:(RollbarSource)source
                   eventBody:(nonnull RollbarTelemetryBody *)body;

/// Records/captures a telemetry event
/// @param level telemetry event level
/// @param body telemetry event body
- (void)recordEventWithLevel:(RollbarLevel)level
                   eventBody:(nonnull RollbarTelemetryBody *)body;

/// Records/captures a telemetry event
/// @param level relevant Rollbar log level
/// @param type telemetry event type
/// @param data event data
- (void)recordEventForLevel:(RollbarLevel)level
                       type:(RollbarTelemetryType)type
                       data:(nullable NSDictionary<NSString *, id> *)data;

/// Records/captures a telemetry View event
/// @param level relevant Rollbar log level
/// @param element view element
/// @param extraData event data
- (void)recordViewEventForLevel:(RollbarLevel)level
                        element:(nonnull NSString *)element
                      extraData:(nullable NSDictionary<NSString *, id> *)extraData;

/// Records/captures a telemetry Network event
/// @param level relevant Rollbar log level
/// @param method call method
/// @param url call URL
/// @param statusCode call status code
/// @param extraData event data
- (void)recordNetworkEventForLevel:(RollbarLevel)level
                            method:(nonnull NSString *)method
                               url:(nonnull NSString *)url
                        statusCode:(nonnull NSString *)statusCode
                         extraData:(nullable NSDictionary<NSString *, id> *)extraData;

/// Records/captures a telemetry Connectivity event
/// @param level relevant Rollbar log level
/// @param status connectivity status
/// @param extraData event data
- (void)recordConnectivityEventForLevel:(RollbarLevel)level
                                 status:(nonnull NSString *)status
                              extraData:(nullable NSDictionary<NSString *, id> *)extraData;

/// Records/captures a telemetry Error event
/// @param level relevant Rollbar log level
/// @param message error message
/// @param extraData event data
- (void)recordErrorEventForLevel:(RollbarLevel)level
                         message:(nonnull NSString *)message
                       extraData:(nullable NSDictionary<NSString *, id> *)extraData;

/// Records/captures a telemetry Error event
/// @param level relevant Rollbar log level
/// @param from navigation starting point
/// @param to navigation end point
/// @param extraData event data
- (void)recordNavigationEventForLevel:(RollbarLevel)level
                                 from:(nonnull NSString *)from
                                   to:(nonnull NSString *)to
                            extraData:(nullable NSDictionary<NSString *, id> *)extraData;

/// Records/captures a telemetry Manual/Custom event
/// @param level relevant Rollbar log level
/// @param extraData event data
- (void)recordManualEventForLevel:(RollbarLevel)level
                         withData:(nonnull NSDictionary<NSString *, id> *)extraData;

/// Records/captures a telemetry Log event
/// @param level relevant Rollbar log level
/// @param message log message
/// @param extraData event data
- (void)recordLogEventForLevel:(RollbarLevel)level
                       message:(nonnull NSString *)message
                     extraData:(nullable NSDictionary<NSString *, id> *)extraData;

#pragma mark - Telemetry cache access methods

-(nonnull NSArray<RollbarTelemetryEvent *> *)getAllEvents;

/// Gets all the currently captured telemetry data/events
- (nullable NSArray *)getAllData;

/// Clears all the currently captured telemetry data/events
- (void)clearAllData;


@end
