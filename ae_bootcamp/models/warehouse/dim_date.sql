select 
    format_date('%F',d) as id,
    d as full_date,
    extract(YEAR from d) as year,
    extract(WEEK from d) as year_week,
    extract(DAY from d) as year_day,
    extract(YEAR from d) as fiscal_year,
    format_date('%Q', d) as fiscal_qtr,
    extract(MONTH from d) as month,
    format_date('%B', d) as month_name,
    format_date('%w', d) as week_day,
    format_date('%A', d) as day_name,
    (case when format_date ('%A', d) in ('Saturday', 'Sunday') then 0 else 1 end) as day_is_weekday,
from (
    select *
    from 
    unnest(generate_date_array('2014-01-01','2050-01-01', interval 1 day)) as d
)
--generate_date_array crea una lista con un día por cada fecha entre 2014 y 2050, y unnest convierte esa lista en filas.
-- Cada fila se completa con atributos de la fecha (año, mes, nombre del día, si es fin de semana). 
--day_is_weekday vale 0 para sábado y domingo, y 1 para el resto.