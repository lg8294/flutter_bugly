#import "FlutterBuglyPlugin.h"
#import <Bugly/Bugly.h>

@implementation FlutterBuglyPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  FlutterMethodChannel* channel = [FlutterMethodChannel
      methodChannelWithName:@"crazecoder/flutter_bugly"
            binaryMessenger:[registrar messenger]];
  FlutterBuglyPlugin* instance = [[FlutterBuglyPlugin alloc] init];
  [registrar addMethodCallDelegate:instance channel:channel];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
  if ([@"initBugly" isEqualToString:call.method]) {
      NSString *appId = call.arguments[@"appId"];
      BOOL b = [self isBlankString:appId];
      if(!b){
          BuglyConfig * config = [[BuglyConfig alloc] init];
          [self setChannel:call config:config];
          [self setAppVersion:call config:config];
          [self unexpectedTerminatingDetectionEnable:call config:config];
          [self blockMonitorEnable:call config:config];
          [self debugMode:call config:config];
          [self symbolicateInProcessEnable:call config:config];
          [self setReportLogLevel:call config:config];
          [Bugly startWithAppId:appId config:config];
          if (config.debugMode) {
              NSLog(@"Bugly appId: %@", appId);
          }
          NSDictionary * dict = @{@"message":@"Bugly 初始化成功",@"appId":appId, @"isSuccess":@YES};
          NSData * jsonData = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:nil];
          NSString * json = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];

          result(json);
      }else{
          NSDictionary * dict = @{@"message":@"Bugly appId不能为空", @"isSuccess":@NO};
          NSData * jsonData = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:nil];
          NSString * json = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
          
          result(json);
      }
      
  }else if([@"postCatchedException" isEqualToString:call.method]){
      NSString *crash_type = call.arguments[@"crash_type"];
      NSString *crash_detail = call.arguments[@"crash_detail"];
      NSString *crash_message = call.arguments[@"crash_message"];
      if ([self isBlankString:crash_detail]) {
          crash_message = @"";
      }
      if ([self isBlankString:crash_type]) {
          crash_type = crash_message;
      }
      NSArray *stackTraceArray = [crash_detail componentsSeparatedByString:@""];
      NSDictionary *data = call.arguments[@"crash_data"];
      if(data == nil){
        data = [NSMutableDictionary dictionary];
      }

      [Bugly reportExceptionWithCategory:5 name:crash_type reason:crash_message callStack:stackTraceArray extraInfo:data terminateApp:NO];
      result(nil);
  }else if([@"setUserId" isEqualToString:call.method]){
      NSString *userId = call.arguments[@"userId"];
      if (![self isBlankString:userId]) {
          [Bugly setUserIdentifier:userId];
      }
      result(nil);
  }else if([@"setUserTag" isEqualToString:call.method]){
      NSNumber *userTag = call.arguments[@"userTag"];
      if (userTag!=nil) {
          NSInteger anInteger = [userTag integerValue];
          [Bugly setTag:anInteger];
      }
      result(nil);
  }else if([@"setAppVersion" isEqualToString:call.method]){
      NSString *appVersion = call.arguments[@"appVersion"];
      if (![self isBlankString:appVersion]) {
          [Bugly updateAppVersion:appVersion];
      }
      result(nil);
  }else if([@"putUserData" isEqualToString:call.method]){
      NSString *key = call.arguments[@"key"];
      NSString *value = call.arguments[@"value"];
      if (![self isBlankString:key]&&![self isBlankString:value]){
          [Bugly setUserValue:value forKey:key];
      }
      result(nil);
  }else if([@"log" isEqualToString:call.method]){
      NSNumber *level = call.arguments[@"log_level"];
      NSString *tag = call.arguments[@"log_tag"];
      NSString *message = call.arguments[@"log_message"];
      [self log:level tag:tag message:message];
      result(nil);
  }else {
      result(FlutterMethodNotImplemented);
  }
}

- (void) setChannel:(FlutterMethodCall*)call config:(BuglyConfig*) config{
    NSString *channel = call.arguments[@"channel"];
    BOOL isChannelEmpty = [self isBlankString:channel];
    if(!isChannelEmpty){
      config.channel = channel;
    }
}

- (void) setAppVersion:(FlutterMethodCall*)call config:(BuglyConfig*) config{
    NSString *appVersion = call.arguments[@"appVersion"];
    BOOL isAppVersionEmpty = [self isBlankString:appVersion];
    if(!isAppVersionEmpty){
      config.version = appVersion;
    }
}

- (void) setDeviceId:(FlutterMethodCall*)call config:(BuglyConfig*) config{
    NSString *deviceId = call.arguments[@"deviceId"];
    BOOL isDeviceIdEmpty = [self isBlankString:deviceId];
    if(!isDeviceIdEmpty){
      config.deviceIdentifier = deviceId;
    }
}

- (void) setBlockMonitorTimeout:(FlutterMethodCall*)call config:(BuglyConfig*) config{
    NSNumber *blockMonitorTimeoutNumber = call.arguments[@"blockMonitorTimeout"];
    double blockMonitorTimeout = [blockMonitorTimeoutNumber doubleValue];
    config.blockMonitorTimeout = blockMonitorTimeout;
}

- (void) unexpectedTerminatingDetectionEnable:(FlutterMethodCall*)call config:(BuglyConfig*) config{
    BOOL unexpectedTerminatingDetectionEnable = [call.arguments[@"unexpectedTerminatingDetectionEnable"] boolValue];
    config.unexpectedTerminatingDetectionEnable = unexpectedTerminatingDetectionEnable;
}

- (void) blockMonitorEnable:(FlutterMethodCall*)call config:(BuglyConfig*) config{
    BOOL blockMonitorEnable = [call.arguments[@"blockMonitorEnable"] boolValue];
    config.blockMonitorEnable = blockMonitorEnable;
}

- (void) debugMode:(FlutterMethodCall*)call config:(BuglyConfig*) config{
    BOOL debugMode = [call.arguments[@"debugMode"] boolValue];
    config.debugMode = debugMode;
}

- (void) symbolicateInProcessEnable:(FlutterMethodCall*)call config:(BuglyConfig*) config{
    BOOL symbolicateInProcessEnable = [call.arguments[@"symbolicateInProcessEnable"] boolValue];
    config.symbolicateInProcessEnable = symbolicateInProcessEnable;
}

- (void) setReportLogLevel:(FlutterMethodCall*)call config:(BuglyConfig*) config{
    NSNumber *level = call.arguments[@"reportLogLevel"];
    if (level!=nil&&![level isEqual:[NSNull null]]) {
        NSInteger anInteger = [level integerValue];
        config.reportLogLevel = anInteger;
    }
}

- (void) log:(NSNumber*)level tag:(NSString*)tag message:(NSString*)message{
    NSInteger anInteger = 0;
    if (level!=nil) {
        anInteger = [level integerValue];
    }
    switch (anInteger) {
        case (long)BuglyLogLevelVerbose:
            [BuglyLog level:BuglyLogLevelVerbose tag:tag log:@"%@", message];
            break;
        case (long)BuglyLogLevelError:
            [BuglyLog level:BuglyLogLevelError tag:tag log:@"%@", message];
            break;
        case (long)BuglyLogLevelWarn:
            [BuglyLog level:BuglyLogLevelWarn tag:tag log:@"%@", message];
            break;
        case (long)BuglyLogLevelInfo:
            [BuglyLog level:BuglyLogLevelInfo tag:tag log:@"%@", message];
            break;
        case (long)BuglyLogLevelDebug:
            [BuglyLog level:BuglyLogLevelDebug tag:tag log:@"%@", message];
            break;
        default:
            [BuglyLog level:BuglyLogLevelSilent tag:tag log:@"%@", message];
            break;
    }
    
}

- (BOOL) isBlankString:(NSString *)string {
    if (string == nil || string == NULL) {
        return YES;
    }
    
    if ([string isKindOfClass:[NSNull class]]) {
        return YES;
    }
    if ([[string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] length]==0) {
        return YES;
    }
    return NO;
    
}

@end
