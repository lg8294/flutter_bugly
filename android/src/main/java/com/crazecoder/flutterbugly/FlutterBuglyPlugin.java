package com.crazecoder.flutterbugly;

import android.annotation.SuppressLint;
import android.app.Activity;
import android.text.TextUtils;

import androidx.annotation.NonNull;

import com.crazecoder.flutterbugly.bean.BuglyInitResultInfo;
import com.crazecoder.flutterbugly.utils.JsonUtil;
import com.crazecoder.flutterbugly.utils.MapUtil;
import com.tencent.bugly.crashreport.CrashReport;

import java.util.Objects;

import io.flutter.BuildConfig;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;


/**
 * FlutterBuglyPlugin
 */
public class FlutterBuglyPlugin implements FlutterPlugin, MethodCallHandler {
    private Result result;
    private boolean isResultSubmitted = false;
    private FlutterPluginBinding flutterPluginBinding;
    private MethodChannel channel;
//    private Activity activity;


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
        isResultSubmitted = false;
        this.result = result;
        switch (call.method) {
            case "initBugly":
                if (call.hasArgument("appId")) {
//                if (call.hasArgument("autoInit")) {
//                    Beta.autoInit = false;
//                }
//                if (call.hasArgument("enableHotfix")) {
//                    Beta.enableHotfix = call.argument("enableHotfix");
//                }
//                if (call.hasArgument("autoCheckUpgrade")) {
//                    Beta.autoCheckUpgrade = call.argument("autoCheckUpgrade");
//                }
//                if (call.hasArgument("autoDownloadOnWifi")) {
//                    Beta.autoDownloadOnWifi = call.argument("autoDownloadOnWifi");
//                }
//                if (call.hasArgument("initDelay")) {
//                    int delay = call.argument("initDelay");
//                    Beta.initDelay = delay * 1000;
//                }
//                if (call.hasArgument("enableNotification")) {
//                    Beta.enableNotification = call.argument("enableNotification");
//                }
//                if (call.hasArgument("upgradeCheckPeriod")) {
//                    int period = call.argument("upgradeCheckPeriod");
//                    Beta.upgradeCheckPeriod = period * 1000;
//                }
//                if (call.hasArgument("showInterruptedStrategy")) {
//                    Beta.showInterruptedStrategy = call.argument("showInterruptedStrategy");
//                }
//                if (call.hasArgument("canShowApkInfo")) {
//                    Beta.canShowApkInfo = call.argument("canShowApkInfo");
//                }
//                if (call.hasArgument("customUpgrade")) {
//                    boolean customUpgrade = call.argument("customUpgrade");
//                    /*在application中初始化时设置监听，监听策略的收取*/
//                    Beta.upgradeListener = customUpgrade ? new UpgradeListener() {
//                        @Override
//                        public void onUpgrade(int ret, UpgradeInfo strategy, boolean isManual, boolean isSilence) {
//                            Map<String, Object> data = new HashMap<>();
//                            data.put("upgradeInfo", JsonUtil.toJson(MapUtil.deepToMap(strategy)));
//                            channel.invokeMethod("onCheckUpgrade", data);
//                        }
//                    } : null;
//                }
//                Beta.canShowUpgradeActs.add(activity.getClass());

                    String appId = Objects.requireNonNull(call.argument("appId")).toString();
                    CrashReport.initCrashReport(flutterPluginBinding.getApplicationContext(), appId, BuildConfig.DEBUG);
                    if (call.hasArgument("channel")) {
                        String channel = call.argument("channel");
                        if (!TextUtils.isEmpty(channel))
                            CrashReport.setAppChannel(flutterPluginBinding.getApplicationContext(), channel);
                    }
                    result(getResultBean(true, appId, "Bugly 初始化成功"));
                } else {
                    result(getResultBean(false, null, "Bugly appId不能为空"));
                }
                break;
            case "setUserId":
                if (call.hasArgument("userId")) {
                    String userId = call.argument("userId");
                    CrashReport.setUserId(flutterPluginBinding.getApplicationContext(), userId);
                }
                result(null);
                break;
            case "setUserTag":
                if (call.hasArgument("userTag")) {
                    Integer userTag = call.argument("userTag");
                    if (userTag != null)
                        CrashReport.setUserSceneTag(flutterPluginBinding.getApplicationContext(), userTag);
                }
                result(null);
                break;
            case "putUserData":
                if (call.hasArgument("key") && call.hasArgument("value")) {
                    String userDataKey = call.argument("key");
                    String userDataValue = call.argument("value");
                    CrashReport.putUserData(flutterPluginBinding.getApplicationContext(), userDataKey, userDataValue);
                }
                result(null);
                break;
            case "checkUpgrade":
            case "getUpgradeInfo":
//            UpgradeInfo strategy = Beta.getUpgradeInfo();
//            result(strategy);
                //            boolean isManual = false;
//            boolean isSilence = false;
//            if (call.hasArgument("isManual")) {
//                isManual = call.argument("isManual");
//            }
//            if (call.hasArgument("isSilence")) {
//                isSilence = call.argument("isSilence");
//            }
//            Beta.checkUpgrade(isManual, isSilence);
                result(null);
                break;
            case "setAppChannel":
                String channel = call.argument("channel");
                if (!TextUtils.isEmpty(channel)) {
                    CrashReport.setAppChannel(flutterPluginBinding.getApplicationContext(), channel);
                }
                result(null);
                break;
            case "postCatchedException":
                postException(call);
                result(null);
                break;
            default:
                result.notImplemented();
                isResultSubmitted = true;
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
        CrashReport.postException(8, "Flutter Exception", message, detail, null);

    }

    private void result(Object object) {
        if (result != null && !isResultSubmitted) {
            if (object == null) {
                result.success(null);
            } else {
                result.success(JsonUtil.toJson(MapUtil.deepToMap(object)));
            }
            isResultSubmitted = true;
        }
    }

    private BuglyInitResultInfo getResultBean(boolean isSuccess, String appId, String msg) {
        BuglyInitResultInfo bean = new BuglyInitResultInfo();
        bean.setSuccess(isSuccess);
        bean.setAppId(appId);
        bean.setMessage(msg);
        return bean;
    }
}