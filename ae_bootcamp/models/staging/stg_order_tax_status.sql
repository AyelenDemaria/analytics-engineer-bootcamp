with source as (

    select * from {{ source('northwind','order_tax_status')}}

)
select * from source 