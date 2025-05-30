
---
## 🎯 Objetivo general

Tienes un modelo incremental en dbt (`dim_customers_historical_load_control`) y quieres que su comportamiento **cambie dinámicamente** según un **modo de carga**:

### 📦 Modo de carga: controlado por una tabla

Tienes una tabla de control: `int_load_control_master` que indica para cada modelo:

| table\_nm                                 | load\_mode | max\_chg\_dt |
| ----------------------------------------- | ---------- | ------------ |
| dim\_customers\_historical\_load\_control | FULL       | *null*       |
| dim\_customers\_historical\_load\_control | DELTA      | 2025-05-19   |

---

## 🧠 ¿Qué lógica quieres aplicar?

1. **Si `load_mode` es `'FULL'`**:

   * El modelo debe comportarse como si fuese una carga **full**: borrar todo (`DELETE`) y volver a cargar desde cero.

2. **Si `load_mode` es `'DELTA'`**:

   * El modelo solo debe insertar los registros **nuevos o actualizados** desde una fecha (`max_chg_dt` o similar).
   * Esta lógica se basa en que tu fuente (`customers_snapshot`) es un snapshot SCD2, así que puedes filtrar por `int_tec_fr_dt` o `int_tec_to_dt`.

---

## 🧪 ¿Qué necesitas para probar que funciona?

### Para probar el modo FULL:

1. Asegúrate de que en la tabla de control tienes:

   ```sql
   UPDATE int_load_control_master
   SET load_mode = 'FULL'
   WHERE table_nm = 'dim_customers_historical_load_control';
   ```

2. Lanza el modelo:

   ```bash
   dbt run --select dim_customers_historical_load_control
   ```

3. Verifica en los logs que se hizo un `DELETE FROM dim_customers_historical_load_control`.

---

### Para probar el modo DELTA:

1. Asegúrate de que en la tabla de control tienes:

   ```sql
   UPDATE int_load_control_master
   SET load_mode = 'DELTA',
       max_chg_dt = '2025-05-19'
   WHERE table_nm = 'dim_customers_historical_load_control';
   ```

2. Cambia tus datos de `customers.csv` para que algunos tengan fechas mayores a `'2025-05-19'` en el campo `updated_at`.

3. Ejecuta `dbt seed` para actualizar los datos:

   ```bash
   dbt seed --select customers
   ```

4. Luego lanza el modelo:

   ```bash
   dbt run --select dim_customers_historical_load_control
   ```

5. Deberías ver que **solo se insertan los nuevos cambios** (basado en `int_tec_fr_dt > max_date`).

---

## 🧩 ¿Dónde estás ahora?

Ya tienes:

* La macro `get_control_params(model_name)` que te devuelve `load_mode` y `max_chg_dt`.
* Una macro `delete_if_full_mode()` que borra la tabla si `load_mode == 'FULL'`.

Y en tu modelo:

* Estás intentando usar `control.load_mode` y filtrar por `int_tec_fr_dt > max_date`.

