# Simulados de Concursos

Aplicativo Flutter offline para importar cadernos de questões em JSON, resolver simulados, corrigir respostas e acompanhar o histórico.

## Estrutura

```text
lib/
  models/       # Question, Notebook e Attempt
  services/     # SQLite e parser/validador JSON
  providers/    # estado global com Provider
  screens/      # início, resolução, resultado e histórico
  widgets/      # componentes reutilizáveis
  main.dart
example/
  simulado_exemplo.json
```

## Como executar

1. Instale o Flutter estável e configure Android Studio/Xcode conforme a plataforma.
2. Como este código foi criado em um diretório vazio, gere os arquivos nativos uma vez:

```bash
flutter create . --platforms=android,ios
```

3. No diretório do projeto, execute:

```bash
flutter pub get
flutter run
```

4. No aplicativo, toque em **Importar JSON** e selecione `example/simulado_exemplo.json`.

Para gerar o APK:

```bash
flutter build apk
```

O arquivo será criado em `build/app/outputs/flutter-apk/app-release.apk`.

Para iOS (em macOS com Xcode):

```bash
flutter build ios
```

O banco SQLite é criado no diretório de documentos do aplicativo. A importação valida todos os campos obrigatórios, descarta itens inválidos e mostra os detalhes ao usuário.
