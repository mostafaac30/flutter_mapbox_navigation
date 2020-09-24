part of navigation;

@visibleForTesting
class MapBoxNavigationFactory {
  final MethodChannel _methodChannel;
  final EventChannel _routeEventchannel;
  final ValueSetter<RouteEvent> _routeEventNotifier;

  MapBoxNavigationFactory(
      this._methodChannel, this._routeEventchannel, this._routeEventNotifier);

  Stream<RouteEvent> _onRouteEvent;
  StreamSubscription<RouteEvent> _routeEventSubscription;

  ///Current Device OS Version
  Future<String> get platformVersion => _methodChannel
      .invokeMethod('getPlatformVersion')
      .then<String>((dynamic result) => result);

  ///Total distance remaining in meters along route.
  Future<double> get distanceRemaining => _methodChannel
      .invokeMethod<double>('getDistanceRemaining')
      .then<double>((dynamic result) => result);

  ///Total seconds remaining on all legs.
  Future<double> get durationRemaining => _methodChannel
      .invokeMethod<double>('getDurationRemaining')
      .then<double>((dynamic result) => result);

  ///Show the Navigation View and Begins Direction Routing
  ///
  /// [origin] must not be null. It must have a longitude, latitude and name.
  /// [destination] must not be null. It must have a longitude, latitude and name.
  /// [mode] defaults to drivingWithTraffic
  /// [simulateRoute] if true will simulate the route as if you were driving. Always true on iOS Simulator
  /// [language] 2-letter ISO 639-1 code for language. This property affects the sentence contained within the RouteStep.instructions property, but it does not affect any road names contained in that property or other properties such as RouteStep.name. Defaults to "en" if an unsupported language is specified. The languages in this link are supported: https://docs.mapbox.com/android/navigation/overview/localization/ or https://docs.mapbox.com/ios/api/navigation/0.14.1/localization-and-internationalization.html
  ////// [mapStyleURL] The Url of the style the Navigation MapView should use
  ///
  /// Begins to generate Route Progress
  ///
  Future startNavigation(
      {WayPoint origin,
      WayPoint destination,
      MapBoxNavigationMode mode = MapBoxNavigationMode.drivingWithTraffic,
      bool simulateRoute = false,
      String language,
      VoiceUnits units,
      String mapStyleURL}) async {
    assert(origin != null);
    assert(origin.name != null);
    assert(origin.latitude != null);
    assert(origin.longitude != null);
    assert(destination != null);
    assert(destination.name != null);
    assert(destination.latitude != null);
    assert(destination.longitude != null);
    final Map<String, Object> args = <String, dynamic>{
      "originName": origin.name,
      "originLatitude": origin.latitude,
      "originLongitude": origin.longitude,
      "destinationName": destination.name,
      "destinationLatitude": destination.latitude,
      "destinationLongitude": destination.longitude,
      "mode": mode.toString().split('.').last,
      "simulateRoute": simulateRoute,
      "language": language,
      "units": units?.toString()?.split('.')?.last,
      "mapStyleURL": mapStyleURL
    };
    _routeEventSubscription = _streamRouteEvent.listen(_onProgressData);
    await _methodChannel
        .invokeMethod('startNavigation', args)
        .then<String>((dynamic result) => result);
  }

  ///Show the Navigation View and Begins Direction Routing
  ///
  /// [WayPoints] must not be null. A collection of [WayPoint](longitude, latitude and name). Must be at least 2 or at most 25. Cannot use drivingWithTraffic mode if more than 3-waypoints.
  /// [mode] defaults to drivingWithTraffic
  /// [simulateRoute] if true will simulate the route as if you were driving. Always true on iOS Simulator
  /// [language] 2-letter ISO 639-1 code for language. This property affects the sentence contained within the RouteStep.instructions property, but it does not affect any road names contained in that property or other properties such as RouteStep.name. Defaults to "en" if an unsupported language is specified. The languages in this link are supported: https://docs.mapbox.com/android/navigation/overview/localization/ or https://docs.mapbox.com/ios/api/navigation/0.14.1/localization-and-internationalization.html
  /// [isOptimized] if true, will reorder the routes to optimize navigation for time and shortest distance using the Travelling Salesman Algorithm. Always false for now
  /// [allowsUTurnAtWayPoints] If the value of this property is true, a returned route may require an immediate U-turn at an intermediate waypoint. At an intermediate waypoint, if the value of this property is false, each returned route may continue straight ahead or turn to either side but may not U-turn. This property has no effect if only two waypoints are specified.
  /// [mapStyleURL] The Url of the style the Navigation MapView should use
  /// Begins to generate Route Progress
  ///
  Future startNavigationWithWayPoints(
      {List<WayPoint> wayPoints,
      MapBoxNavigationMode mode = MapBoxNavigationMode.drivingWithTraffic,
      bool simulateRoute = false,
      String language,
      VoiceUnits units,
      String mapStyleURL,
      bool allowsUTurnAtWayPoints,
      bool isOptimized = false}) async {
    assert(wayPoints != null);
    assert(wayPoints.length > 1);
    if (Platform.isIOS && wayPoints.length > 3) {
      assert(mode != MapBoxNavigationMode.drivingWithTraffic,
          "Error: Cannot use drivingWithTraffic Mode when you have more than 3 Stops");
    }
    var pointList = List<Map<String, Object>>();

    for (int i = 0; i < wayPoints.length; i++) {
      var wayPoint = wayPoints[i];
      assert(wayPoint != null);
      assert(wayPoint.name != null);
      assert(wayPoint.latitude != null);
      assert(wayPoint.longitude != null);

      final pointMap = <String, dynamic>{
        "Order": i,
        "Name": wayPoint.name,
        "Latitude": wayPoint.latitude,
        "Longitude": wayPoint.longitude,
      };
      pointList.add(pointMap);
    }
    var i = 0;
    var wayPointMap =
        Map.fromIterable(pointList, key: (e) => i++, value: (e) => e);

    final Map<String, Object> args = <String, dynamic>{
      "wayPoints": wayPointMap,
      "mode": mode.toString().split('.').last,
      "simulateRoute": simulateRoute,
      "language": language,
      "units": units?.toString()?.split('.')?.last,
      "isOptimized": isOptimized,
      "allowsUTurnAtWayPoints": allowsUTurnAtWayPoints,
      "mapStyleURL": mapStyleURL
    };

    _routeEventSubscription = _streamRouteEvent.listen(_onProgressData);
    await _methodChannel
        .invokeMethod('startNavigationWithWayPoints', args)
        .then<String>((dynamic result) => result);
  }

  ///Ends Navigation and Closes the Navigation View
  Future<bool> finishNavigation() async {
    var success = await _methodChannel.invokeMethod('finishNavigation', null);
    return success;
  }

  void _onProgressData(RouteEvent event) {
    if (_routeEventNotifier != null) _routeEventNotifier(event);

    if (event.eventType == MapBoxEvent.on_arrival)
      _routeEventSubscription.cancel();
  }

  Stream<RouteEvent> get _streamRouteEvent {
    if (_onRouteEvent == null) {
      _onRouteEvent = _routeEventchannel
          .receiveBroadcastStream()
          .map((dynamic event) => _parseRouteEvent(event));
    }
    return _onRouteEvent;
  }

  RouteEvent _parseRouteEvent(String jsonString) {
    RouteEvent event;
    var map = json.decode(jsonString);
    var progressEvent = RouteProgressEvent.fromJson(map);
    if (progressEvent != null && progressEvent.isProgressEvent) {
      event = RouteEvent(
          eventType: MapBoxEvent.progress_change, data: progressEvent);
    } else
      event = RouteEvent.fromJson(map);
    return event;
  }
}