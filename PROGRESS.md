# 🚀 Estado del Proyecto: Finanzas Compartidas (Flutter + Supabase)

---

## 📌 Resumen de Features Completados

1. **Infraestructura Base y Clean Architecture**:
   - Estructura modular por feature en `lib/features/<feature>/{domain, data, presentation}` siguiendo las directivas de `AGENTS.md`.
   - Módulos `core`: `errors`, `usecases`, `network`, `theming`, `utils`, `router`.
   - Configuración de `analysis_options.yaml` con reglas estrictas de linter.

2. **Esquema de Base de Datos en Supabase (PostgreSQL)**:
   - 7 archivos de migración SQL en `supabase/migrations/` cubriendo `profiles`, `groups`, `group_members`, `wallets`, `transactions`, `budget_weeks` y `settlements`.
   - Row Level Security (RLS) habilitado en todas las tablas con políticas restrictivas y función `SECURITY DEFINER` `is_group_member` para evitar recursión en PostgreSQL.
   - Trigger en servidor `on auth.users insert` para la creación automática de perfiles.

3. **Feature `auth` (Autenticación)**:
   - Pantallas: Login, Registro y Recuperación de contraseña.
   - `AuthNotifier` en Riverpod gestionando estados: `unauthenticated`, `authenticated`, `loading`, `error`.
   - Redirección automática declarativa en `GoRouter`.
   - Manejo de errores de Supabase Auth traducidos al español.

4. **Feature `wallets` (Gestión de Billeteras)**:
   - Entidad `Wallet` (Efectivo / Tarjeta).
   - Lista visual de billeteras personales con balance y tipo.
   - Formulario de creación y diálogo de ajuste manual de balance con confirmación explícita.
   - Pruebas unitarias en `test/features/wallets/`.

5. **Feature `groups` (Grupos y Presupuesto Semanal)**:
   - Flujo de creación de grupo con pre-cálculo y generación automática de $N$ filas iguales en `budget_weeks`.
   - Sistema de invitación por código de 6 caracteres y canje automático.
   - Pantalla de Resumen de Grupo con indicador de progreso y desglose por semanas.
   - **Modelo de Fondo Compartido**: Calculado dinámicamente sobre las transacciones compartidas (`is_shared = true`), evitando duplicidad de saldos en billeteras.

6. **Feature `transactions` (Gestor de Gastos de Alta Velocidad)**:
   - Formulario de registro de 1 solo paso con teclado numérico gigante táctil, chips de categorías con íconos (🍔 Comida, 🚗 Transporte, 💡 Servicios, etc.), selector de billetera y toggles (`¿Es compartido?`, `Extraordinario`).
   - Impacto directo: descuenta de la billetera del pagador e incrementa `spent_amount` en la `budget_week` actual.
   - **Optimistic UI Updates** con rollback en Riverpod para reflejo instantáneo en UI.
   - **Modo Offline y Sincronización**: Cola local (`SharedPreferences`) y sincronización automática vía `connectivity_plus`.
   - Lista de transacciones con filtros por categoría, usuario y extraordinarios.

7. **Motor de Recálculo Presupuestario (`BudgetRecalculator`)**:
   - Módulo de **dominio puro** (sin dependencias de Flutter ni Supabase).
   - Algoritmo `closeWeekAndRedistribute`: calcula remanente o sobregiro al cerrar una semana y lo redistribuye equitativamente entre las semanas futuras restantes.
   - Pseudocódigo documentado en el código fuente.
   - 9 casos de prueba unitarios pasando al 100%.
   - `CloseWeekUseCase` que persiste los nuevos `adjusted_amount` en Supabase.

8. **Módulo `settlements` ("Cuentas Claras")**:
   - Módulo de **dominio puro** `SettlementCalculator` que calcula aportes y balance neto individual.
   - **Algoritmo Greedy de Minimización de Pagos**: empareja al mayor deudor con el mayor acreedor hasta saldar las cuentas con el número mínimo de transferencias.
   - Pantalla *"Cuentas Claras"* con resumen de aportes y tarjetas de pago (*"Fulano debe transferir $X a Zutano"*).
   - Botón *"Marcar como pagado"* que inserta en la tabla `settlements` de Supabase.
   - Pruebas unitarias para parejas (2 personas), roomies (3 personas), cuentas saldadas en 0.0 y múltiples miembros.

9. **Dashboard Principal Interactivo y Métricas (`dashboard`)**:
   - **Barra de Progreso Doble**: Compara % de tiempo transcurrido del ciclo vs % de dinero gastado. Alerta en rojo/naranja cuando el % gastado supera al % de tiempo por más de 10 puntos porcentuales (umbral configurable).
   - **Gráfica de Gastos por Categoría**: Implementada con `fl_chart` (`PieChart`), leyenda interactiva con montos ($) y porcentajes (%).
   - **Vista de Gastos Extraordinarios**: Filtrado en tiempo real de transacciones no me recurrente (`isExtraordinary == true`) con insignias y totales.
   - **Optimización Riverpod**: Cache de datos en StateNotifier family y sub-providers de grano fino (`dashboardProgressProvider`, `dashboardCategoryExpensesProvider`, `dashboardExtraordinaryExpensesProvider`) para evitar refetching y rebuilds innecesarios.

10. **Conexión Supabase Realtime & Sincronización Reactiva**:
    - **Suscripción Filtrada por Grupo**: Escucha eventos `INSERT`, `UPDATE` y `DELETE` en la tabla `transactions` con filtro por `group_id`.
    - **Actualizaciones Incrementales**: `upsertTransaction` en `TransactionsNotifier` y actualización en caliente de métricas del Dashboard y balances de Billeteras sin recargar toda la pantalla.
    - **Reconexión con Exponential Backoff & Jitter**: Reintenta automáticamente la suscripción al canal si la conexión falla o se cierra (1s, 2s, 4s, 8s, 16s, máx 32s).
    - **Deduplicación Offline + Realtime**: Generación de UUIDs RFC4122 client-side y verificación en `TransactionRepositoryImpl` para evitar que la cola offline duplique entradas transmitidas por Realtime.

---

## 📁 Archivos Modificados / Creados

```
supabase/migrations/
├── 20260722000001_create_enums_and_types.sql
├── 20260722000002_create_profiles.sql
├── 20260722000003_create_groups_and_members.sql
├── 20260722000004_create_wallets.sql
├── 20260722000005_create_transactions.sql
├── 20260722000006_create_budget_weeks.sql
└── 20260722000007_create_settlements.sql

lib/
├── core/
│   ├── errors/ (failures.dart, exceptions.dart)
│   ├── network/ (supabase_client.dart)
│   ├── router/ (app_router.dart)
│   ├── theming/ (app_theme.dart)
│   ├── usecases/ (usecase.dart)
│   └── utils/ (formatters.dart, uuid_generator.dart)
├── features/
│   ├── auth/ (domain, data, presentation)
│   ├── wallets/ (domain, data, presentation)
│   ├── groups/ (domain, data, presentation, services/budget_recalculator.dart)
│   ├── transactions/ (domain, data, presentation, datasources/transaction_realtime_data_source.dart)
│   ├── settlements/ (domain, data, presentation, services/settlement_calculator.dart)
│   └── dashboard/ (domain, presentation, services/dashboard_calculator.dart)
├── main.dart
test/
├── features/
│   ├── wallets/data/repositories/wallet_repository_impl_test.dart
│   ├── groups/data/repositories/group_repository_impl_test.dart
│   ├── groups/domain/services/budget_recalculator_test.dart
│   ├── transactions/data/repositories/transaction_repository_impl_test.dart
│   ├── transactions/data/datasources/transaction_realtime_data_source_test.dart
│   ├── transactions/presentation/providers/realtime_transactions_test.dart
│   ├── settlements/domain/services/settlement_calculator_test.dart
│   └── dashboard/ (domain/services/dashboard_calculator_test.dart, presentation/providers/dashboard_provider_test.dart, presentation/widgets/double_progress_bar_widget_test.dart, presentation/widgets/category_chart_widget_test.dart)
└── widget_test.dart
```

---

## 🏛️ Arquitectura Definida

- **Clean Architecture Modular**: Aislamiento estricto entre `domain` (entidades puras, use cases, contratos e interfaces), `data` (modelos, datasources remotos/locales, repositorios) y `presentation` (widgets, screens y Riverpod providers).
- **Gestión de Estado**: `flutter_riverpod` (`StateNotifierProvider`, `Provider.family`, `StreamProvider.family`).
- **Navegación Declarativa**: `go_router` con guardas de autenticación dinámicas.
- **Módulos de Dominio Puros**: Calculadoras puras inmutables (`BudgetRecalculator`, `SettlementCalculator`, `DashboardCalculator`) sin acoplamiento a frameworks.
- **Calidad de Código**: 48 pruebas unitarias y de widgets ejecutadas con **100% de éxito** y **0 advertencias en `flutter analyze`**.

---

## 🔮 Tareas Pendientes para Próximas Sesiones

1. **Notificaciones y Recordatorios**:
   - Alertas push o locales para cierres de semana y saldos pendientes.
2. **Exportación de Datos**:
   - Generación de reportes resumidos en PDF y CSV.
3. **Despliegue e Integración Continua**:
   - Configuración de pipelines CI/CD y despliegue de Edge Functions en Supabase.
