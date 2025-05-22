{% macro generate_schema_name(custom_schema_name, node) -%}

    {%- set default_schema = target.schema -%}
    {%- if custom_schema_name is none -%}
        {{ default_schema }}
    {%- else -%}
        {{ custom_schema_name | trim }} 
    {%- endif -%}
{%- endmacro %}


#}
If you have a custom_schema_name (elementary), it will append it into the default_schema (public): public_elementary.
To override this behavior you should create a macro (a .SQL file) inside your macros folder with the same name 
but with different instructions. For example, if you want the schema to be exactly your custom_schema, you can do it like this. 
Delete this macro if we want the default behavior: default_schema_name + custom_schema_name
#}