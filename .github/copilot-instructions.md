# Ravapecont — Instrucciones de ejecución

## Proyecto
- Flutter/Dart.
- Ruta local: E:\APP FLUTTER CODIGO\HORLABS\ravapecont.
- App privada de facturación y presupuestos.
- UI: desktop, minimalista, fondo negro y texto blanco.
- Firebase ya configurado. No ejecutar flutterfire configure ni firebase init salvo orden explícita.

## Protocolo obligatorio
1. Ejecuta la tarea solicitada; no respondas sólo con un plan.
2. Si una instrucción es técnicamente posible, aplícala sin pedir confirmación.
3. Si existe un error previo fuera de alcance, no bloquees la tarea:
   - Modifica únicamente los archivos autorizados.
   - Ejecuta la validación indicada.
   - Separa errores preexistentes de errores introducidos.
4. No declares “hecho”, “corregido” o “completado” sin ejecutar la validación solicitada.
5. Después de modificar, informa siempre:
   - Archivos modificados.
   - Cambio concreto por archivo.
   - Resultado literal de validación.
6. Si se solicita un cambio de un único archivo, no modifiques ningún otro.
7. Si el archivo contiene una inconsistencia, corrige sólo lo necesario para cumplir el objetivo; no propongas refactors no solicitados.
8. No inventes requisitos, dependencias, arquitecturas ni archivos.
9. No uses `!` sobre valores anulables sin una comprobación previa.
10. No uses `dynamic`, `print`, `debugPrint`, suppressions de analyzer ni comentarios TODO para ocultar problemas.
11. No añadir dependencias sin orden explícita.
12. No modificar:
    - android/
    - ios/
    - web/
    - Gradle
    - Firebase Console
    - firebase_options.dart
    - firebase_initializer.dart
    salvo orden explícita.

## Validación
- Para microcambios: ejecutar sólo `flutter analyze`.
- Para cambios funcionales cerrados: ejecutar:
  flutter analyze
  flutter test
- Si la validación falla por un archivo fuera del alcance:
  informar ruta, línea y error, sin modificarlo.
- No detener la tarea por errores externos preexistentes.

## Definición de terminado
Una tarea no está terminada hasta que:
1. El cambio pedido existe en el archivo.
2. El diff muestra sólo los cambios autorizados.
3. La validación indicada se ha ejecutado.
4. El resultado se informa literalmente.

## Respuesta final
Formato estricto:
1. Estado: COMPLETA / BLOQUEADA.
2. Archivos modificados.
3. Cambio exacto.
4. Validación literal.
5. Bloqueo externo, sólo si existe.
