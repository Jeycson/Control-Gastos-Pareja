# Directivas de Arquitectura para Flutter

## Clean Architecture Standards
- Estructura modular por feature: `lib/features/<feature_name>/{data, domain, presentation}`.
- **Domain Layer:** Debe contener entidades puras, casos de uso (use cases) e interfaces de repositorios. NO debe depender de Flutter ni de paquetes de UI.
- **Data Layer:** Debe implementar los repositorios, data sources (remoto/local) y modelos (con `fromJson` / `toJson`).
- **Presentation Layer:** Debe contener widgets, controladores de estado (ej. BLoC o Riverpod) y páginas.
- Evita importar archivos de `data` directamente dentro de la capa de `presentation`.

## Reglas de Código
- Usa `freezed` o `equatable` para inmutabilidad cuando sea requerido.
