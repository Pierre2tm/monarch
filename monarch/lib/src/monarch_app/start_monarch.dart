import 'dart:async';

import 'package:stack_trace/stack_trace.dart';
import 'package:monarch_utils/log.dart';
import 'package:monarch_utils/log_config.dart';

import 'monarch_data_instance.dart';
import 'ready_signal.dart';
import 'device_definitions.dart';
import 'story_scale_definitions.dart';
import 'active_theme.dart';
import 'channel_methods_sender.dart';
import 'channel_methods_receiver.dart';
import 'standard_themes.dart';
import 'stories_errors.dart';
import 'story_app.dart';
import 'monarch_data.dart';
import 'vm_service_client.dart';
import 'monarch_binding.dart';

final _logger = Logger('Start');

void startMonarch(MonarchData Function() getMonarchData) {
  Chain.capture(() {
    _startMonarch(getMonarchData);
  }, onError: handleUncaughtError);
}

void _startMonarch(MonarchData Function() getMonarchData) async {
  final monarchBinding = MonarchBinding.ensureInitialized() as MonarchBinding;

  _setUpLog();
  readySignal.loading();
  loadMonarchDataInstance(getMonarchData);
  handleFlutterFrameworkErrors();

  monarchBinding.reassembleCallback = () async {
    loadMonarchDataInstance(getMonarchData);
    await channelMethodsSender.sendMonarchData(monarchDataInstance);
  };

  monarchBinding.attachRootWidget(MonarchStoryApp());
  monarchBinding.scheduleFrame();

  receiveChannelMethodCalls();
  await _connectToVmService();
  await _sendDefinitions();
  await channelMethodsSender.sendMonarchData(monarchDataInstance);
  await channelMethodsSender.sendReadySignal();
}

void _setUpLog() {
  writeLogEntryStream(print, printTimestamp: false, printLoggerName: true);
}

Future<void> _connectToVmService() async {
  try {
    await vmServiceClient.connect();
  } catch (e, s) {
    _logger.warning(
        'Error while connecting to VM Service. Features like Debug '
        'Paint may not work.',
        e,
        s);
  }
}

Future<void> _sendDefinitions() async {
  await channelMethodsSender.sendPing();
  await channelMethodsSender.sendDefaultTheme(activeTheme.defaultMetaTheme.id);
  await channelMethodsSender.sendDeviceDefinitions(DeviceDefinitions());
  await channelMethodsSender.sendStoryScaleDefinitions(StoryScaleDefinitions());
  await channelMethodsSender.sendStandardThemes(StandardThemes());
}
