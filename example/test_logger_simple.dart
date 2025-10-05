import 'package:strategic_logger/logger.dart';
import 'package:strategic_logger/src/strategies/console/console_log_strategy.dart';

void main() async {
  print('Iniciando teste completo do Strategic Logger...\n');

  // Configurar o logger com console moderno
  await logger.initialize(
    strategies: [
      ConsoleLogStrategy(
        useModernFormatting: true,
        useColors: true,
        useEmojis: true,
        showTimestamp: true,
        showContext: true,
      ),
    ],
    level: LogLevel.debug, // Mudado para debug para ver todos os logs
    enablePerformanceMonitoring: true,
    enableModernConsole: true,
  );

  print('\nTestando TODOS os níveis de log:\n');

  // Teste de todos os níveis disponíveis
  logger.debug('Esta é uma mensagem de DEBUG');
  logger.info('Esta é uma mensagem de INFO');
  logger.warning('Esta é uma mensagem de WARNING');
  logger.error('Esta é uma mensagem de ERROR');
  logger.fatal('Esta é uma mensagem FATAL');

  print('\nTestando logs estruturados com contexto:\n');

  // Teste de logs estruturados com diferentes contextos
  logger.info('Usuário fez login', context: {
    'userId': '12345',
    'email': 'usuario@exemplo.com',
    'timestamp': DateTime.now().toIso8601String(),
    'device': 'iPhone 15',
    'appVersion': '2.1.0',
  });

  logger.warning('Uso de memória alto', context: {
    'memoryUsage': '85%',
    'threshold': '80%',
    'processId': '1234',
    'timestamp': DateTime.now().toIso8601String(),
  });

  logger.error('Erro ao processar pagamento', context: {
    'paymentId': 'pay_67890',
    'amount': 99.99,
    'currency': 'BRL',
    'errorCode': 'INSUFFICIENT_FUNDS',
    'userId': '12345',
  });

  print('\nTestando logs de performance:\n');

  // Teste de logs de performance
  final stopwatch = Stopwatch()..start();
  
  // Simular processamento pesado
  await Future.delayed(Duration(milliseconds: 150));
  
  stopwatch.stop();
  
  logger.info('Processamento concluído', context: {
    'duration': '${stopwatch.elapsedMilliseconds}ms',
    'itemsProcessed': 150,
    'memoryUsage': '45.2MB',
    'cpuUsage': '23%',
  });

  print('\nTestando logs em lote com diferentes níveis:\n');

  // Teste de logs em lote com diferentes níveis
  for (int i = 1; i <= 10; i++) {
    if (i % 3 == 0) {
      logger.error('Erro no item $i', context: {
        'itemId': i,
        'errorType': 'validation_error',
        'progress': '${(i / 10 * 100).round()}%',
      });
    } else if (i % 2 == 0) {
      logger.warning('Aviso no item $i', context: {
        'itemId': i,
        'warningType': 'slow_processing',
        'progress': '${(i / 10 * 100).round()}%',
      });
    } else {
      logger.info('Processando item $i', context: {
        'itemId': i,
        'progress': '${(i / 10 * 100).round()}%',
      });
    }
  }

  print('\nTestando logs com exceções e stack traces:\n');

  // Teste de logs com exceções
  try {
    throw Exception('Erro simulado para teste');
  } catch (e, stackTrace) {
    logger.error(e, stackTrace: stackTrace, context: {
      'errorType': 'simulated_exception',
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  try {
    throw StateError('Erro de estado crítico');
  } catch (e, stackTrace) {
    logger.fatal(e, stackTrace: stackTrace, context: {
      'errorType': 'critical_state_error',
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  print('\nTestando logs estruturados com LogEvent:\n');

  // Teste de logs estruturados usando LogEvent
  final loginEvent = LogEvent(
    eventName: 'user_login',
    eventMessage: 'Usuário fez login com sucesso',
    parameters: {
      'userId': '12345',
      'method': 'email_password',
      'timestamp': DateTime.now().toIso8601String(),
    },
  );

  logger.logStructured(LogLevel.info, loginEvent);

  final errorEvent = LogEvent(
    eventName: 'payment_error',
    eventMessage: 'Falha no processamento do pagamento',
    parameters: {
      'paymentId': 'pay_12345',
      'errorCode': 'CARD_DECLINED',
      'amount': 50.00,
      'currency': 'BRL',
    },
  );

  logger.logStructured(LogLevel.error, errorEvent);

  print('\nEstatísticas de performance:\n');

  // Obter estatísticas
  final stats = logger.getPerformanceStats();
  print('Estatísticas do logger:');
  print('- Total de logs: ${stats['totalLogs']}');
  print('- Logs por segundo: ${stats['logsPerSecond']?.toStringAsFixed(2)}');
  print('- Tempo médio de processamento: ${stats['averageProcessingTime']?.toStringAsFixed(2)}ms');

  print('\nTeste completo concluído! Verifique os logs acima para ver a formatação moderna do Strategic Logger.');
  print('Todos os logs agora devem ter o formato: [HYPN-TECH][STRATEGIC-LOGGER][LEVEL]');
  
  // Limpar recursos
  logger.dispose();
}
