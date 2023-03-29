package com.crazecoder.flutterbugly;

import android.content.Context;
import android.text.TextUtils;

import androidx.annotation.NonNull;

import com.crazecoder.flutterbugly.bean.BuglyInitResultInfo;
import com.crazecoder.flutterbugly.utils.JsonUtil;
import com.crazecoder.flutterbugly.utils.MapUtil;
import com.tencent.bugly.crashreport.CrashReport;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;


/**
 * FlutterBuglyPlugin
 */
public class FlutterBuglyPlugin implements FlutterPlugin, MethodCallHandler {
    private FlutterPluginBinding flutterPluginBinding;
    private MethodChannel channel;

    Context getContext() {
        return flutterPluginBinding.getApplicationContext();
    }

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
        this.flutterPluginBinding = binding;
        channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "crazecoder/flutter_bugly");
        channel.setMethodCallHandler(this);
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        channel.setMethodCallHandler(null);
        flutterPluginBinding = null;
    }


    @Override
    public void onMethodCall(final MethodCall call, @NonNull final Result result) {
        switch (call.method) {
            case "initBugly":
                if (call.hasArgument("appId")) {
                    String appId = call.argument("appId");
                    boolean isDebug = call.argument("isDebug") == Boolean.TRUE;
                    CrashReport.UserStrategy userStrategy = new CrashReport.UserStrategy(getContext());
                    userStrategy.setAppChannel((String) call.argument("channel"));
                    userStrategy.setDeviceID((String) call.argument("deviceId"));
                    userStrategy.setDeviceModel((String) call.argument("deviceModel"));
                    if (call.hasArgument("reportDelay")) {
                        Integer reportDelay = call.argument("reportDelay");
                        if (reportDelay != null) {
                            userStrategy.setAppReportDelay(reportDelay);
                        }
                    }
                    CrashReport.setIsDevelopmentDevice(getContext(), isDebug);
                    CrashReport.initCrashReport(getContext(), appId, isDebug, userStrategy);

                    result.success(JsonUtil.toJson(MapUtil.deepToMap(getResultBean(true, appId, "Bugly 初始化成功"))));
                } else {
                    result.success(JsonUtil.toJson(MapUtil.deepToMap(getResultBean(false, null, "Bugly appId不能为空"))));
                }
                break;
            case "setUserId":
                if (call.hasArgument("userId")) {
                    String userId = call.argument("userId");
                    CrashReport.setUserId(getContext(), userId);
                }
                result.success(null);
                break;
            case "setUserTag":
                if (call.hasArgument("userTag")) {
                    Integer userTag = call.argument("userTag");
                    if (userTag != null)
                        CrashReport.setUserSceneTag(getContext(), userTag);
                }
                result.success(null);
                break;
            case "putUserData":
                if (call.hasArgument("key") && call.hasArgument("value")) {
                    String userDataKey = call.argument("key");
                    String userDataValue = call.argument("value");
                    CrashReport.putUserData(getContext(), userDataKey, userDataValue);
                }
                result.success(null);
                break;
            case "setAppChannel":
                String channel = call.argument("channel");
                if (!TextUtils.isEmpty(channel)) {
                    CrashReport.setAppChannel(getContext(), channel);
                }
                result.success(null);
                break;
            case "setDeviceId":
                String deviceId = call.argument("deviceId");
                if (!TextUtils.isEmpty(deviceId)) {
                    CrashReport.setDeviceId(getContext(), deviceId);
                }
                result.success(null);
                break;
            case "setDeviceModel":
                String deviceModel = call.argument("deviceModel");
                if (!TextUtils.isEmpty(deviceModel)) {
                    CrashReport.setDeviceModel(getContext(), deviceModel);
                }
                result.success(null);
                break;
            case "postCatchedException":
                postException(call);
                result.success(null);
                break;
            default:
                result.notImplemented();
                break;
        }

    }

    private void postException(MethodCall call) {
        String message = "";
        String detail = null;
        if (call.hasArgument("crash_message")) {
            message = call.argument("crash_message");
        }
        if (call.hasArgument("crash_detail")) {
            detail = call.argument("crash_detail");
        }
        if (TextUtils.isEmpty(detail)) return;
        CrashReport.postException(8, message, null, detail, null);

    }

    private BuglyInitResultInfo getResultBean(boolean isSuccess, String appId, String msg) {
        BuglyInitResultInfo bean = new BuglyInitResultInfo();
        bean.setSuccess(isSuccess);
        bean.setAppId(appId);
        bean.setMessage(msg);
        return bean;
    }
}