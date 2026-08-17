with source as (

    select * from {{ source('northwind','order_tax_status')}}

)
select 
    *,
    current_timestamp () as ingestion_timestamp
from source