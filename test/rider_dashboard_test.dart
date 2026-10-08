import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_delivery/screens/rider_dashboard_screen.dart';
import 'package:food_delivery/state/user_state.dart';

// 1x1 transparent PNG data
final List<int> _transparentImage = <int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49,
  0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06,
  0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44,
  0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00, 0x05, 0x00, 0x01, 0x0D,
  0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42,
  0x60, 0x82,
];

class _TestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _FakeHttpClient();
  }
}

class _FakeHttpClient implements HttpClient {
  @override
  bool autoUncompress = true;
  @override
  Duration? connectionTimeout;
  @override
  Duration idleTimeout = const Duration(seconds: 15);
  @override
  int? maxConnectionsPerHost;
  @override
  String? userAgent;

  @override
  void addCredentials(Uri url, String realm, HttpClientCredentials credentials) {}
  @override
  void addProxyCredentials(String host, int port, String realm, HttpClientCredentials credentials) {}
  @override
  set authenticate(Future<bool> Function(Uri url, String scheme, String? realm)? f) {}
  @override
  set authenticateProxy(Future<bool> Function(String host, int port, String scheme, String? realm)? f) {}
  @override
  set badCertificateCallback(bool Function(X509Certificate cert, String host, int port)? callback) {}
  @override
  void close({bool force = false}) {}
  @override
  set findProxy(String Function(Uri url)? f) {}

  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _FakeHttpClientRequest();
  @override
  Future<HttpClientRequest> open(String method, String host, int port, String path) async => _FakeHttpClientRequest();
  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async => _FakeHttpClientRequest();
  @override
  Future<HttpClientRequest> postUrl(Uri url) async => _FakeHttpClientRequest();
  @override
  Future<HttpClientRequest> putUrl(Uri url) async => _FakeHttpClientRequest();
  @override
  Future<HttpClientRequest> deleteUrl(Uri url) async => _FakeHttpClientRequest();
  @override
  Future<HttpClientRequest> patchUrl(Uri url) async => _FakeHttpClientRequest();
  @override
  Future<HttpClientRequest> headUrl(Uri url) async => _FakeHttpClientRequest();
  @override
  Future<HttpClientRequest> post(String host, int port, String path) async => _FakeHttpClientRequest();
  @override
  Future<HttpClientRequest> put(String host, int port, String path) async => _FakeHttpClientRequest();
  @override
  Future<HttpClientRequest> delete(String host, int port, String path) async => _FakeHttpClientRequest();
  @override
  Future<HttpClientRequest> patch(String host, int port, String path) async => _FakeHttpClientRequest();
  @override
  Future<HttpClientRequest> head(String host, int port, String path) async => _FakeHttpClientRequest();
  @override
  Future<HttpClientRequest> get(String host, int port, String path) async => _FakeHttpClientRequest();

  @override
  set connectionFactory(Future<ConnectionTask<Socket>> Function(Uri url, String? proxyHost, int? proxyPort)? f) {}
  @override
  set keyLog(Function(String line)? callback) {}
}

class _FakeHttpClientRequest implements HttpClientRequest {
  @override
  final HttpHeaders headers = _FakeHttpHeaders();
  @override
  bool bufferOutput = true;
  @override
  int contentLength = 0;
  @override
  Encoding encoding = utf8;
  @override
  bool followRedirects = true;
  @override
  int maxRedirects = 5;
  @override
  bool persistentConnection = true;

  @override
  void add(List<int> data) {}
  @override
  void addError(Object error, [StackTrace? stackTrace]) {}
  @override
  Future addStream(Stream<List<int>> stream) async {}
  @override
  Future<HttpClientResponse> close() async => _FakeHttpClientResponse();
  @override
  Future<HttpClientResponse> get done async => _FakeHttpClientResponse();
  @override
  Future flush() async {}
  @override
  void write(Object? obj) {}
  @override
  void writeAll(Iterable objects, [String separator = ""]) {}
  @override
  void writeCharCode(int charCode) {}
  @override
  void writeln([Object? obj = ""]) {}
  @override
  void abort([Object? exception, StackTrace? stackTrace]) {}

  @override
  HttpConnectionInfo? get connectionInfo => null;
  @override
  List<Cookie> get cookies => [];
  @override
  String get method => 'GET';
  @override
  Uri get uri => Uri.parse('http://fake.test');
}

class _FakeHttpHeaders implements HttpHeaders {
  @override
  List<String>? operator [](String name) => null;
  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {}
  @override
  void clear() {}
  @override
  void forEach(void Function(String name, List<String> values) action) {}
  @override
  void noFolding(String name) {}
  @override
  void remove(String name, Object value) {}
  @override
  void removeAll(String name) {}
  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {}
  @override
  String? value(String name) => null;
  @override
  bool chunkedTransferEncoding = false;
  @override
  int contentLength = 0;
  @override
  ContentType? contentType;
  @override
  DateTime? date;
  @override
  DateTime? expires;
  @override
  String? host;
  @override
  DateTime? ifModifiedSince;
  @override
  bool persistentConnection = true;
  @override
  int? port;
}

class _FakeHttpClientResponse extends Stream<List<int>> implements HttpClientResponse {
  @override
  final HttpHeaders headers = _FakeHttpHeaders();
  @override
  int get statusCode => 200;
  @override
  int get contentLength => _transparentImage.length;
  @override
  HttpClientResponseCompressionState get compressionState => HttpClientResponseCompressionState.notCompressed;
  @override
  StreamSubscription<List<int>> listen(void Function(List<int> event)? onData,
      {Function? onError, void Function()? onDone, bool? cancelOnError}) {
    return Stream<List<int>>.fromIterable([_transparentImage]).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }
  @override
  X509Certificate? get certificate => null;
  @override
  HttpConnectionInfo? get connectionInfo => null;
  @override
  List<Cookie> get cookies => [];
  @override
  Future<Socket> detachSocket() => throw UnimplementedError();
  @override
  bool get isRedirect => false;
  @override
  String get reasonPhrase => 'OK';
  @override
  Future<HttpClientResponse> redirect([String? method, Uri? url, bool? followLoops]) => throw UnimplementedError();
  @override
  List<RedirectInfo> get redirects => [];
  @override
  bool get persistentConnection => true;
}

void main() {
  setUpAll(() {
    HttpOverrides.global = _TestHttpOverrides();
  });

  group('Rider Dashboard Tests', () {
    testWidgets('Renders Rider Dashboard and all 4 Bottom Nav items', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final userState = UserState();
      userState.setRole(UserRole.rider);

      await tester.pumpWidget(
        MaterialApp(
          home: RiderDashboardScreen(userState: userState),
        ),
      );
      await tester.pumpAndSettle();

      // Check BottomNavigationBar destinations: Home, Rides, Completed, Profile
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Rides'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);

      // Verify Home Analytics Metrics are shown
      expect(find.text('Total Rides'), findsOneWidget);
      expect(find.text('Delivered'), findsOneWidget);
      expect(find.text('Accepted'), findsOneWidget);
      expect(find.text('On the Way'), findsOneWidget);
      expect(find.text('Cancelled'), findsOneWidget);

      // Tap on Rides (Active / Uncompleted Rides)
      await tester.tap(find.text('Rides'));
      await tester.pumpAndSettle();
      expect(find.text('Active Rides'), findsOneWidget);
      expect(find.textContaining('All Active'), findsOneWidget);

      // Tap on Completed Rides (Checkmark destination)
      await tester.tap(find.text('Completed'));
      await tester.pumpAndSettle();
      expect(find.text('Completed Rides'), findsOneWidget);

      // Tap on Profile
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();
      expect(find.text('Rider Profile'), findsOneWidget);
      expect(find.text('Manage Personal Details'), findsOneWidget);
      expect(find.text('Change Password & Security'), findsOneWidget);

      // Test App Bar Profile Avatar navigation
      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();
      expect(find.text('Rider Analytics'), findsOneWidget);

      // Tap the profile avatar in the AppBar
      await tester.tap(find.byTooltip('My Profile'));
      await tester.pumpAndSettle();
      expect(find.text('Rider Profile'), findsOneWidget);
    });
  });
}
