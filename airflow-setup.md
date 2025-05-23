
# 🚀 dbt + Airflow + Elementary – Local Workflow Guide

Este documento resume el flujo de trabajo local para ejecutar pipelines de dbt con Airflow y Elementary, usando Docker.

---

## 📦 Requisitos previos

- Docker y Docker Compose instalados
- Este repositorio clonado localmente
- Archivo `docker-compose.yml` en la raíz del proyecto

---

## 🧭 Navegación

Abre una terminal y dirígete al directorio raíz del proyecto:

```bash
cd ~/Developer/data-engineering-env
````

---

## 🔁 Primer uso (o tras limpiar todo)

Si es la primera vez que usas el entorno o has hecho un `docker compose down -v`:

```bash
docker compose build                # (Re)construye la imagen personalizada con git/dbt/edr
docker compose up airflow-init     # Inicializa la DB de Airflow y crea el usuario admin
```

---

## 🚀 Inicio habitual

Para iniciar todo el stack de servicios (Airflow, PostgreSQL, etc.):

```bash
docker compose up -d
```

Esto levanta en segundo plano:

* Airflow Webserver
* Airflow Scheduler
* Airflow metadata Postgres
* PostgreSQL de dbt

---

## 🖥 Interfaz de usuario de Airflow

Accede desde tu navegador a:

👉 [http://localhost:8080](http://localhost:8080)

Usa estas credenciales:

* **Usuario:** `admin`
* **Contraseña:** `admin`

Pasos:

1. Despausa el DAG `dbt_pipeline` si está pausado
2. Ejecuta el DAG manualmente con el botón ▶️

---

## 📊 Ver reporte de calidad de datos (Elementary)

Para generar y visualizar el reporte HTML:

1. Asegúrate de tener montado este volumen en `docker-compose.yml`:

```yaml
volumes:
  - ./elementary_report:/home/airflow/.elementary/report
```

2. Ejecuta el DAG hasta el final (incluso si hay tests fallidos)

3. Abre el reporte en tu navegador:

```bash
open ./elementary_report/index.html    # macOS
# o
xdg-open ./elementary_report/index.html  # Linux
```

---

## 🧯 Apagar el entorno

### Detener servicios sin borrar datos:

```bash
docker compose down
```

### Detener y borrar volúmenes (⚠️ perderás datos de Airflow y Postgres):

```bash
docker compose down -v
```

---

## 📝 Flujo resumen

| Escenario                      | Comando                               |
| ------------------------------ | ------------------------------------- |
| 🏗 Primer uso o limpieza total | `build` → `up airflow-init` → `up -d` |
| 🏃‍♂️ Uso diario               | `up -d`                               |
| ▶️ Ejecutar DAG                | Desde la UI de Airflow                |
| 📈 Ver reporte HTML            | `open ./elementary_report/index.html` |
| ⏹ Detener entorno              | `docker compose down`                 |
| 🔥 Detener y borrar todo       | `docker compose down -v`              |
---


# 🧭 Guía: Cómo usar un solo `profiles.yml` para dbt y Elementary en local y en Airflow (Docker)

## 🧩 Situación

Cuando trabajas con `dbt` y `elementary` tanto en tu terminal local como en Airflow (que corre dentro de Docker), te enfrentas a este problema común:

* **Localmente**, la base de datos Postgres se accede por `localhost`.
* **En Docker (Airflow)**, esa misma base se accede por el nombre del servicio Docker, normalmente `postgres`.

Si usas `localhost` en `profiles.yml`, Airflow no puede conectar.
Si usas `postgres`, tú no puedes conectar desde tu terminal local.

## ❌ Enfoques incorrectos

* Mantener dos perfiles (`dbt_project_docker` y `dbt_project_local`) → 🔁 duplicación innecesaria
* Cambiar el `host` manualmente cada vez → 😩 propenso a errores

## ✅ Solución

Usar `env_var()` en el `host` del `profiles.yml`, lo que te permite:

* Ejecutar localmente sin hacer nada adicional.
* Hacer que Airflow pase la variable `DBT_HOST=postgres` al entorno.

Esto permite que ambos entornos compartan un único perfil **dinámico** y consistente.

## 🛠️ ¿Qué hay que hacer?

1. En `profiles.yml`, usar:

   ```yaml
   host: "{{ env_var('DBT_HOST', 'localhost') }}"
   ```

2. En tu DAG de Airflow, pasar la variable:

   ```python
   env = {
     "DBT_PROJECT_DIR": "/opt/dbt_project",
     "PATH": "...",
     "DBT_HOST": "postgres"  # <- clave para funcionar en Docker
   }
   ```

3. Ejecutar `dbt` y `edr` normalmente desde terminal:

   ```bash
   dbt build --profile dbt_project
   edr report --profile elementary
   ```

   > ✔ No hace falta exportar nada, porque `localhost` se usa por defecto.

4. Airflow seguirá usando el mismo perfil, pero con `host: postgres`.

## 📌 Resultado

* 🎯 Un solo `profiles.yml` válido para todos los entornos
* ⚙️ Compatible con `dbt` y `elementary`
* 📦 Sin duplicación ni edición manual
* 🧘‍♂️ Sin necesidad de recordar en qué entorno estás

---


