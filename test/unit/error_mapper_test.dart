import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lungsense_pro/core/errors/failure.dart';
import 'package:lungsense_pro/core/network/error_mapper.dart';

void main() {
  group('ErrorMapper.fromResponse', () {
    test('simple string detail', () {
      final f = ErrorMapper.fromResponse(400, {
        'detail': 'Invalid login credentials',
      });
      expect(f.kind, FailureKind.badRequest);
      expect(f.statusCode, 400);
      expect(f.message, 'Invalid login credentials');
      expect(f.code, isNull);
    });

    test('structured account-status detail', () {
      final f = ErrorMapper.fromResponse(403, {
        'detail': {
          'code': 'account_pending_approval',
          'message': 'Your account is waiting for approval',
        },
      });
      expect(f.kind, FailureKind.forbidden);
      expect(f.code, 'account_pending_approval');
      expect(f.message, 'Your account is waiting for approval');
    });

    test('FastAPI 422 validation list maps field errors', () {
      final f = ErrorMapper.fromResponse(422, {
        'detail': [
          {
            'loc': ['body', 'password'],
            'msg': 'Value error, Password must include a symbol',
            'type': 'value_error',
          },
          {
            'loc': ['body', 'email'],
            'msg': 'value is not a valid email address',
            'type': 'value_error',
          },
        ],
      });
      expect(f.kind, FailureKind.validation);
      expect(f.fieldErrors['password'], 'Password must include a symbol');
      expect(f.fieldErrors['email'], 'value is not a valid email address');
      expect(f.message, 'Password must include a symbol');
    });

    test('status codes map to kinds', () {
      expect(
        ErrorMapper.fromResponse(401, null).kind,
        FailureKind.unauthorized,
      );
      expect(ErrorMapper.fromResponse(404, null).kind, FailureKind.notFound);
      expect(ErrorMapper.fromResponse(409, null).kind, FailureKind.validation);
      expect(ErrorMapper.fromResponse(429, null).kind, FailureKind.rateLimited);
      expect(
        ErrorMapper.fromResponse(503, null).kind,
        FailureKind.serviceUnavailable,
      );
      expect(ErrorMapper.fromResponse(500, null).kind, FailureKind.server);
      expect(ErrorMapper.fromResponse(418, null).kind, FailureKind.unknown);
    });

    test('non-JSON body is tolerated', () {
      final f = ErrorMapper.fromResponse(502, '<html>Bad gateway</html>');
      expect(f.kind, FailureKind.server);
      expect(f.message, isNull);
    });
  });

  group('ErrorMapper.fromDio', () {
    final req = RequestOptions(path: '/x');

    test('timeouts', () {
      for (final t in [
        DioExceptionType.connectionTimeout,
        DioExceptionType.sendTimeout,
        DioExceptionType.receiveTimeout,
      ]) {
        expect(
          ErrorMapper.fromDio(DioException(requestOptions: req, type: t)).kind,
          FailureKind.timeout,
        );
      }
    });

    test('connection error', () {
      final f = ErrorMapper.fromDio(
        DioException.connectionError(requestOptions: req, reason: 'refused'),
      );
      expect(f.kind, FailureKind.network);
      expect(f.isConnectivity, isTrue);
    });

    test('bad response uses body', () {
      final f = ErrorMapper.fromDio(
        DioException.badResponse(
          statusCode: 429,
          requestOptions: req,
          response: Response(
            requestOptions: req,
            statusCode: 429,
            data: {'detail': 'Too many attempts'},
          ),
        ),
      );
      expect(f.kind, FailureKind.rateLimited);
      expect(f.message, 'Too many attempts');
    });
  });

  test('Failure.toString never includes the server message', () {
    const f = Failure(
      kind: FailureKind.badRequest,
      message: 'secret@example.com is not confirmed',
    );
    expect(f.toString(), isNot(contains('secret@example.com')));
  });
}
