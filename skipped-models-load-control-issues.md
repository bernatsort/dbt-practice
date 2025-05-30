
---

## 🧾 **Limitación técnica en el control de modelos "skipped" en dbt**

### 📌 **Contexto**

En nuestro proyecto de `dbt`, usamos una tabla de control (`int_load_control_master`) para registrar el estado de ejecución de cada modelo (`OK`, `KO`, `PENDING`, `SKIPPED`, etc.). Este estado se actualiza dinámicamente mediante macros (`mark_model_as_*`) al finalizar la ejecución (`on-run-end` hook).

### ❗**Problema identificado**

Cuando ejecutamos dbt con la instrucción:

```bash
dbt run --exclude dim_customers_historical_load_control
```

el modelo **no es ejecutado** (como se espera), pero **tampoco se marca como `SKIPPED`** en la tabla de control.

### 🔍 **Razón técnica**

dbt expone una variable llamada `results` en el hook `on-run-end`, que contiene únicamente los modelos **que fueron seleccionados y ejecutados efectivamente**.
Por lo tanto:

* Los modelos excluidos mediante `--exclude` **no aparecen en `results`**.
* En consecuencia, nuestros macros como `mark_model_as_skipped(model)` **nunca se ejecutan para esos modelos**.
* Esto **no es un error de implementación**, sino una **limitación del diseño actual de dbt**.

### ✅ **Alternativas posibles (más complejas)**

Para poder identificar y registrar como `SKIPPED` los modelos no ejecutados, tendríamos que:

1. Comparar los modelos definidos en `int_load_control_master` contra los modelos presentes en `results`.
2. Ejecutar una operación auxiliar (`dbt run-operation`) posterior al run para marcar como `SKIPPED` los que faltan.

Esto requeriría:

* Scripts adicionales o lógica en CI/CD.
* Acceso a todos los modelos esperados vs ejecutados.
* Evitar depender solo de `on-run-end`.

### 📌 **Conclusión**

Actualmente **no es posible marcar automáticamente como `SKIPPED` los modelos excluidos de la ejecución (`--exclude`) usando solo los mecanismos estándar de dbt (`on-run-end` + `results`)**.

---


