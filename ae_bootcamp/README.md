# Northwind Analytics Engineering — dbt + BigQuery

Proyecto de analytics engineering de punta a punta: datos transaccionales crudos (Northwind Traders) → staging → data warehouse dimensional estilo Kimball → One Big Tables (OBT) listas para BI. Construido con **dbt Core** sobre **Google BigQuery**.

> **Aclaración:** es un proyecto de aprendizaje, realizado mientras cursaba *Analytics Engineering Bootcamp* en Udemy. El dataset, el caso de negocio y el diseño general provienen del curso; la implementación, la depuración y la documentación de este repositorio son de mi autoría.

## Qué hace

El caso de negocio es una empresa comercializadora (Northwind) con datos de ventas, compras e inventario guardados en una base OLTP normalizada. El objetivo es convertirlos en tablas confiables y listas para el análisis.

```
Exportaciones CSV (OLTP)
      │  carga manual en BigQuery
      ▼
 Data lake      dl_vientodelnorte      tablas crudas, sin tocar
      │  dbt: source()
      ▼
 Staging        stg_*  (tablas)        copia 1:1 + ingestion_timestamp, ajustes de tipo mínimos
      │  dbt: ref()
      ▼
 Warehouse      dim_* / fact_* (tablas) deduplicado, renombrado, modelado (esquema estrella)
      │  dbt: ref()
      ▼
 OBT            obt_* (tablas)         desnormalizadas, una tabla ancha por caso de uso para BI
```

## Modelos

| Capa | Modelos | Materialización |
| --- | --- | --- |
| Staging | 20 modelos `stg_*` (customer, employees, products, suppliers, orders, order_details, purchase_orders, inventory_transactions, …) | tabla |
| Warehouse – dimensiones | `dim_customer`, `dim_employee`, `dim_product`, `dim_date` | tabla (`dim_date`: vista) |
| Warehouse – hechos | `fact_sales`, `fact_inventory`, `fact_purchase_order` | tabla, particionada por fecha |
| OBT | `obt_sales_overview`, `obt_customer_reporting`, `obt_product_inventory` | tabla |

## Decisiones de diseño

- **Modelado dimensional Kimball.** Los hechos y las dimensiones se definieron a partir de una bus matrix y un source-to-target mapping (ver `docs/`), con el grano explícito de cada tabla de hechos.
- **Arquitectura en capas.** Staging aísla la fuente, el warehouse guarda una única definición limpia de cada entidad y la OBT es la salida final para BI.
- **Deduplicación** en las dimensiones con `row_number() over (partition by <clave>)` y `select * except (...)`.
- **Particionado** de las tablas de hechos por fecha, para reducir los bytes leídos en BigQuery.
- **Columnas de auditoría:** `ingestion_timestamp` (staging) e `insertion_timestamp` (warehouse y OBT).
- **Un schema por capa**, configurado con `+schema` en `dbt_project.yml`.

## Calidad de datos

Tests `not_null` y `unique` sobre las claves de las dimensiones (`models/warehouse/schema.yml`). Se ejecutan con:

```bash
dbt test
```

## Comandos utilizados

```bash
dbt run                          # construye todos los modelos
dbt run --select stg_products+   # un modelo y todo lo que depende de él
dbt test                         # corre los tests de calidad
```

## Estructura del proyecto

```
models/
├── staging/        source.yml + stg_*.sql
├── warehouse/      dim_*.sql, fact_*.sql, schema.yml
└── analytics_OBT/  obt_*.sql
docs/               bus matrix y mappings origen-destino
```

## Limitaciones conocidas y próximos pasos

- 5 productos con varios proveedores (`supplier_ids` del tipo `"1;2"`) quedan excluidos en staging; una tabla puente permitiría modelarlos bien.
- `fact_purchase_order` relaciona compras con clientes a través de productos compartidos, lo que multiplica filas; hay que revisar su grano.
- Las dimensiones se sobrescriben (SCD tipo 1); todavía no hay snapshots.
- Los modelos se reconstruyen completos en cada corrida; los modelos incrementales son el paso natural para las tablas de hechos.
- Las OBT todavía no incluyen los atributos de `dim_date`.
- Faltan más tests (`relationships`, `accepted_values`) y la documentación con `dbt docs`.
- No hay orquestación ni CI todavía (por ejemplo, GitHub Actions).

## Herramientas

dbt Core, BigQuery, SQL, Git, VS Code con la extensión *Power User for dbt*.