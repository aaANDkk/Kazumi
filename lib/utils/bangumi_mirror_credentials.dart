// Bangumi mirror API credentials for the search signature flow.
// Release/PR CI injects them via --dart-define=KAZUMI_APPID / KAZUMI_KEY.
const _defaultKazumiId = 'kazumi-hh47hcih6xfodp50';
const _defaultKazumiKey = 'EKlABDVRMb8g5OkCH78SL14riZU4zmkR';

const _kazumiId = String.fromEnvironment('KAZUMI_APPID', defaultValue: _defaultKazumiId);
const _kazumiKey = String.fromEnvironment('KAZUMI_KEY', defaultValue: _defaultKazumiKey);

final Map<String, String> bangumiMirrorCredentials = {
  'id': _kazumiId.isNotEmpty ? _kazumiId : _defaultKazumiId,
  'value': _kazumiKey.isNotEmpty ? _kazumiKey : _defaultKazumiKey,
};
