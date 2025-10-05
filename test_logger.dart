import 'package:strategic_logger/logger.dart';

void main() async {
  print('🚀 Iniciando teste do Strategic Logger...\n');

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
    level: LogLevel.info,
    enablePerformanceMonitoring: true,
    enableModernConsole: true,
  );

  print('\n📝 Testando diferentes níveis de log:\n');

  // Teste de diferentes níveis
  logger.debug('Esta é uma mensagem de debug');
  logger.info('Esta é uma mensagem de informação');
  logger.warning('Esta é uma mensagem de aviso');
  logger.error('Esta é uma mensagem de erro');
  logger.fatal('Esta é uma mensagem fatal');

  print('\n🎯 Testando logs estruturados:\n');

  // Teste de logs estruturados
  logger.info('Usuário fez login', context: {
    'userId': '12345',
    'email': 'usuario@exemplo.com',
    'timestamp': DateTime.now().toIso8601String(),
  });

  logger.error('Erro ao processar pagamento', context: {
    'paymentId': 'pay_67890',
    'amount': 99.99,
    'currency': 'BRL',
    'errorCode': 'INSUFFICIENT_FUNDS',
  });

  print('\n📊 Testando logs de performance:\n');

  // Teste de logs de performance
  final stopwatch = Stopwatch()..start();
  
  // Simular processamento
  await Future.delayed(Duration(milliseconds: 100));
  
  stopwatch.stop();
  
  logger.info('Processamento concluído', context: {
    'duration': '${stopwatch.elapsedMilliseconds}ms',
    'itemsProcessed': 150,
    'memoryUsage': '45.2MB',
  });

  print('\n🔄 Testando logs em lote:\n');

  // Teste de logs em lote
  for (int i = 1; i <= 5; i++) {
    logger.info('Processando item $i', context: {
      'itemId': i,
      'progress': '${(i / 5 * 100).round()}%',
    });
  }

  print('\n📈 Estatísticas de performance:\n');

  // Obter estatísticas
  final stats = logger.getPerformanceStats();
  print('Estatísticas do logger:');
  print('- Total de logs: ${stats['totalLogs']}');
  print('- Logs por segundo: ${stats['logsPerSecond']?.toStringAsFixed(2)}');
  print('- Tempo médio de processamento: ${stats['averageProcessingTime']?.toStringAsFixed(2)}ms');

  print('\n✅ Teste concluído! Verifique os logs acima para ver a formatação moderna do Strategic Logger.');
  
  // Limpar recursos
  logger.dispose();
}
