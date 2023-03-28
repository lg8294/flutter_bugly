import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'bean/init_result_info.dart';

class FlutterBugly {
  FlutterBugly._();

  static const MethodChannel _channel = MethodChannel(
    'crazecoder/flutter_bugly',
  );

  static bool _postCaught = false;

  /// 初始化
  static Future<InitResultInfo> init({
    String? androidAppId,
    String? iOSAppId,
    String? channel, // 自定义渠道标识
    String? deviceId,
    String? deviceModel,
    int reportDelay = 10000, // Bugly会在启动10s后联网同步数据。若您有特别需求，可以修改这个时间。单位毫秒
    bool isDebug = false,
  }) async {
    assert(
      (Platform.isAndroid && androidAppId != null) ||
          (Platform.isIOS && iOSAppId != null),
    );
    assert(_postCaught, 'Run postCatchedException first.');

    Map<String, Object?> map = {
      "appId": Platform.isAndroid ? androidAppId : iOSAppId,
      "channel": channel,
      "deviceId": deviceId,
      "deviceModel": deviceModel,
      "reportDelay": reportDelay,
      "isDebug": isDebug,
    };
    final result = await _channel.invokeMethod('initBugly', map);
    Map resultMap = json.decode(result);
    var resultBean = InitResultInfo.fromJson(resultMap as Map<String, dynamic>);
    return resultBean;
  }

  /// 自定义渠道标识，Android 专用
  static Future<Null> setAppChannel(String channel) async {
    assert(Platform.isAndroid, 'setAppChannel only supports on Android.');
    if (Platform.isAndroid) {
      Map<String, Object> map = {"channel": channel};
      await _channel.invokeMethod('setAppChannel', map);
    }
  }

  /// 设备设备 ID，Android 专用
  static Future<Null> setDeviceId(String deviceId) async {
    assert(Platform.isAndroid, 'setDeviceId only supports on Android.');
    if (Platform.isAndroid) {
      Map<String, Object> map = {"deviceId": deviceId};
      await _channel.invokeMethod('setDeviceId', map);
    }
  }

  /// 设备设备 Model，Android 专用
  static Future<Null> setDeviceModel(String deviceModel) async {
    assert(Platform.isAndroid, 'setDeviceModel only supports on Android.');
    if (Platform.isAndroid) {
      Map<String, Object> map = {"deviceModel": deviceModel};
      await _channel.invokeMethod('setDeviceModel', map);
    }
  }

  /// 设置用户标识
  static Future<Null> setUserId(String userId) async {
    Map<String, Object> map = {"userId": userId};
    await _channel.invokeMethod('setUserId', map);
  }

  /// 设置标签
  /// [userTag] 标签 ID，可在网站生成
  static Future<Null> setUserTag(int userTag) async {
    Map<String, Object> map = {"userTag": userTag};
    await _channel.invokeMethod('setUserTag', map);
  }

  ///设置关键数据，随崩溃信息上报
  static Future<Null> putUserData({
    required String key,
    required String value,
  }) async {
    assert(key.isNotEmpty);
    assert(value.isNotEmpty);
    Map<String, Object> map = {"key": key, "value": value};
    await _channel.invokeMethod('putUserData', map);
  }

  /// 异常上报。该方法等同于 [runZonedGuarded]。
  ///
  /// [callback] 运行的内容。
  /// [onException] 自定义异常处理，可用于异常打印、双上报等定制逻辑。该字段不影响上报。
  /// [filterRegExp] 针对 message 正则过滤异常上报。
  /// [debugUpload] 是否在调试模式也上报。
  static void postCatchedException<T>(
    T callback(), {
    FlutterExceptionHandler? onException,
    String? filterRegExp,
    bool debugUpload = false,
  }) {
    bool _isDebug = false;
    assert(_isDebug = true);
    Isolate.current.addErrorListener(new RawReceivePort((dynamic pair) {
      var isolateError = pair as List<dynamic>;
      var _error = isolateError.first;
      var _stackTrace = isolateError.last;
      Zone.current.handleUncaughtError(_error, _stackTrace);
    }).sendPort);
    // This captures errors reported by the Flutter framework.
    FlutterError.onError = (details) {
      if (details.stack != null) {
        Zone.current.handleUncaughtError(details.exception, details.stack!);
      } else {
        FlutterError.presentError(details);
      }
    };
    _postCaught = true;
    // This creates a [Zone] that contains the Flutter application and stablishes
    // an error handler that captures errors and reports them.
    //
    // Using a zone makes sure that as many errors as possible are captured,
    // including those thrown from [Timer]s, microtasks, I/O, and those forwarded
    // from the `FlutterError` handler.
    //
    // More about zones:
    //
    // - https://api.dartlang.org/stable/1.24.2/dart-async/Zone-class.html
    // - https://www.dartlang.org/articles/libraries/zones
    runZonedGuarded<Future<Null>>(() async {
      callback();
    }, (error, stackTrace) {
      _filterAndUploadException(
        debugUpload,
        _isDebug,
        onException,
        filterRegExp,
        FlutterErrorDetails(exception: error, stack: stackTrace),
      );
    });
  }

  static void _filterAndUploadException(
    debugUpload,
    _isDebug,
    handler,
    filterRegExp,
    FlutterErrorDetails details,
  ) {
    if (!_filterException(
      debugUpload,
      _isDebug,
      handler,
      filterRegExp,
      details,
    )) {
      uploadException(
          message: details.exception.toString(),
          detail: details.stack.toString());
    }
  }

  static bool _filterException(
    bool debugUpload,
    bool _isDebug,
    FlutterExceptionHandler? handler,
    String? filterRegExp,
    FlutterErrorDetails details,
  ) {
    if (handler != null) {
      handler(details);
    } else {
      FlutterError.onError?.call(details);
    }
    // Debug 时默认不上传异常。
    if (!debugUpload && _isDebug) {
      return true;
    }
    // 异常过滤。
    if (filterRegExp != null) {
      RegExp reg = new RegExp(filterRegExp);
      Iterable<Match> matches = reg.allMatches(details.exception.toString());
      if (matches.length > 0) {
        return true;
      }
    }
    return false;
  }

  /// 上报自定义异常信息，data 为文本附件
  /// Android 错误分析 => 跟踪数据 => extraMessage.txt
  /// iOS 错误分析 => 跟踪数据 => crash_attach.log
  static Future<Null> uploadException({
    required String message,
    required String detail,
    Map? data,
  }) async {
    var map = {};
    map.putIfAbsent("crash_message", () => message);
    map.putIfAbsent("crash_detail", () => detail);
    if (data != null) map.putIfAbsent("crash_data", () => data);
    await _channel.invokeMethod('postCatchedException', map);
  }

  static void dispose() {
    _postCaught = false;
  }
}
