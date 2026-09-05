// DanDanPlay API credentials for the client signature flow.
// Release/PR CI injects them via --dart-define=DANDANAPI_APPID / DANDANAPI_KEY.
const _defaultAppId = 'qb998n8g3u';
const _defaultAppKey = '4y2waS6A6yb4uw7Dhd9pmdTzvrF7YUsg';

const _appId = String.fromEnvironment('DANDANAPI_APPID', defaultValue: _defaultAppId);
const _appKey = String.fromEnvironment('DANDANAPI_KEY', defaultValue: _defaultAppKey);

final Map<String, String> dandanCredentials = {
  'id': _appId.isNotEmpty ? _appId : _defaultAppId,
  'value': _appKey.isNotEmpty ? _appKey : _defaultAppKey,
};
