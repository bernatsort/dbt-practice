Aquí tienes un resumen claro y documentado para compartir con tu equipo sobre la problemática que encontraste con `FULL` vs `DELTA` en tu modelo `dim_customers_historical_load_control`.

---

## 🧾 Resumen del problema: Cargas `FULL` vs `DELTA` en modelo historificado

### 🧩 Contexto

El modelo `dim_customers_historical_load_control` es una tabla de dimensiones historificada (SCD2), alimentada a partir del snapshot `customers_snapshot`, y controlada mediante la tabla `int_load_control_master`, que especifica si se debe hacer una carga `FULL` o `DELTA`.

### 🧨 Problema detectado con `DELTA`

Al cambiar el `load_mode` a `DELTA`, el modelo ejecuta la siguiente lógica:

```sql
WHERE int_tec_fr_dt > max_date
   OR (int_tec_to_dt > max_date AND int_tec_to_dt != '9999-12-31')
```

Donde `max_date` es el valor de `MAX(int_tec_fr_dt)` ya presente en la tabla destino.

#### ❌ Resultado inesperado:

* Si `max_date = 2025-05-23` (por ejemplo, de un update de Jane),
* Y luego se carga un nuevo registro histórico con `int_tec_fr_dt = 2025-02-10` (por ejemplo, un nuevo cliente llamado Alice),
* **Ese nuevo cliente no será detectado** ni cargado, porque su fecha es anterior al `max_date` y no pasa el filtro `int_tec_fr_dt > max_date`.

### ✅ Qué ocurre con `FULL`

En cambio, si se usa `FULL`:

* El pre-hook hace un `TRUNCATE` de la tabla destino.
* Se carga todo el contenido completo del snapshot, incluidas versiones antiguas o nuevos registros con fechas anteriores.
* El modelo genera correctamente las filas historificadas (incluso si `int_tec_fr_dt` < `max_date`).

### 🧠 Conclusión

* **`DELTA` es más eficiente**, pero solo es seguro si todos los nuevos registros tienen `int_tec_fr_dt` posterior al `MAX(int_tec_fr_dt)` existente.
* **`FULL` es más robusto**, ya que siempre recrea la historia completa del snapshot, pero es más costoso en tiempo y recursos.

### 🧩 Recomendación

* Si hay posibilidad de que el snapshot incorpore registros atrasados (por ejemplo, nuevas filas historificadas con fechas anteriores), se recomienda usar `FULL`.
* En un flujo productivo maduro y bien ordenado cronológicamente, `DELTA` puede usarse con seguridad y mejor rendimiento.

---

Ejemplo: 
```
1) full
customer_id,first_name,last_name,email,updated_at
2,Jane,Smith,jane@email.com,2025-05-20


dim_customers_historical_load_control
2	Jane	Smith	jane.new@email.com	5d58f88e8662662c9e73b783aa539f30	9999-12-31 00:00:00.000	2025-05-20 00:00:00.000	1	0
```

```
2) full
customer_id,first_name,last_name,email,updated_at
2,Jane,Smith,jane.new@email.com,2025-05-23

dim_customers_historical_load_control
Jane	2	Smith	jane@email.com	5d58f88e8662662c9e73b783aa539f30	2025-05-23 00:00:00.000	2025-05-20 00:00:00.000	0	0
Jane	2	Smith	jane.new@email.com	588db5d8e7d57dbb9cb6a36bc9e76b90	9999-12-31 00:00:00.000	2025-05-23 00:00:00.000	1	0
```

```
3) delta
customer_id,first_name,last_name,email,updated_at
2,Jane,Smith,jane.new@email.com,2025-05-23
3,Alice,Brown,alice@email.com,2025-02-10

dim_customers_historical_load_control
2	Jane	Smith	jane@email.com	5d58f88e8662662c9e73b783aa539f30	2025-05-23 00:00:00.000	2025-05-20 00:00:00.000	0	0
2	Jane	Smith	jane.new@email.com	588db5d8e7d57dbb9cb6a36bc9e76b90	9999-12-31 00:00:00.000	2025-05-23 00:00:00.000	1	0
```
```
--> no nos incluye el nuevo registro porque ese nuevo cliente no será detectado ni cargado, porque su fecha es anterior al max_date y no pasa el filtro int_tec_fr_dt > max_date.
```
```
3) otra vez pero en full: 
2	Jane	Smith	jane@email.com	5d58f88e8662662c9e73b783aa539f30	2025-05-23 00:00:00.000	2025-05-20 00:00:00.000	0	0
2	Jane	Smith	jane.new@email.com	588db5d8e7d57dbb9cb6a36bc9e76b90	9999-12-31 00:00:00.000	2025-05-23 00:00:00.000	1	0
3	Alice	Brown	alice@email.com	280ddc3e8f66ccd0dea10e5014727583	9999-12-31 00:00:00.000	2025-02-10 00:00:00.000	1	0
```


---

## 🧠 ¿Es común este problema con `DELTA` y SCD2?

### ✅ **Sí, es una situación habitual** en entornos con SCD2 (Slowly Changing Dimensions Type 2) cuando se usa un enfoque **incremental basado en fechas** (`int_tec_fr_dt > max_date`).

### 🧨 **Cuándo suele ocurrir:**

* Cuando los datos **no llegan en orden cronológico** (muy común en sistemas donde se reprocesan datos o llegan tarde).
* Si el sistema de origen **genera historificación retroactiva**, es decir, añade registros antiguos o corrige versiones anteriores.
* Cuando se hace un **re-sync** del snapshot que incluye historia previa (p. ej., un resync de todos los clientes con su historia completa).
* En procesos donde **el snapshot se construye con lógica compleja o joins**, y puede variar la historia en ejecuciones posteriores, no solo añadir lo más nuevo.

### 📉 Consecuencia:

* Se pierden nuevas filas "viejas" en modo `DELTA`, porque no superan el filtro `int_tec_fr_dt > max_date`.

---

## 💡 ¿Cómo lo resuelven otros equipos?

### En general, los equipos aplican **una o varias de estas estrategias**:

1. **Cargas `FULL` periódicas** (ej. semanal o mensual) para garantizar integridad histórica.
2. Usar un campo adicional como `load_ts` (fecha de carga real) en lugar de `int_tec_fr_dt`, si quieren controlar las nuevas llegadas independientemente de la fecha lógica.
3. Incluir lógica de detección de "datos fuera de ventana" (out-of-window data) con alertas para decidir cuándo usar `FULL`.
4. Aplicar **snapshots más frecuentes** y comparar hashes o checksums, evitando confiar únicamente en fechas.

---

## ✅ En resumen

* **Sí, es común**.
* No es un fallo de diseño, sino una **limitación inherente al uso de fechas como filtro incremental** en cargas historificadas.
* Requiere criterio y control para elegir entre `FULL` o `DELTA` según la estabilidad, puntualidad y naturaleza del sistema de origen.



# ✅ Si detectas que en modo `DELTA` **te estás perdiendo registros que sí aparecen en el snapshot pero no se están cargando**, **la solución más directa y segura es**:

---

### 🛠️ **Cambiar a modo `FULL` en la `int_load_control_master`**

```sql
UPDATE dw_schema.int_load_control_master
SET load_mode = 'FULL'
WHERE table_nm = 'dim_customers_historical_load_control';
```

### ▶️ Luego ejecutar:

```bash
dbt run --select dim_customers_historical_load_control
```

---

### 💡 ¿Por qué esto soluciona el problema?

* Tu macro `truncate_if_full_mode` se encargará de **vaciar la tabla** antes de la carga.
* Se eliminarán los registros antiguos (incluidos los incompletos).
* Al volver a cargar todos los datos desde el snapshot completo, **recuperas los que no pasaban el filtro de fecha en `DELTA`**.

---

### ⚠️ Recomendación

Después de ejecutar con `FULL`:

* Verifica que todos los datos estén correctos.
* **Vuelve a cambiar a `DELTA`** para futuras ejecuciones, si lo deseas, ya que `FULL` suele tardar más:

```sql
UPDATE dw_schema.int_load_control_master
SET load_mode = 'DELTA'
WHERE table_nm = 'dim_customers_historical_load_control';
```

Opcionalmente, podrías automatizar un fallback: si `DELTA` carga 0 filas y hay diferencias esperadas, lanzar un `FULL`.

---
