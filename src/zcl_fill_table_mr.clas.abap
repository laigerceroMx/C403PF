CLASS zcl_fill_table_mr DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_oo_adt_classrun .
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_fill_table_mr IMPLEMENTATION.


  METHOD if_oo_adt_classrun~main.

    DATA: lt_status   TYPE STANDARD TABLE OF zdt_status_mr,
          lt_priority TYPE STANDARD TABLE OF zdt_priority_mr.

    lt_status = VALUE #( ( client = sy-mandt status_code = 'OP' status_description = 'Open' )
    ( client = sy-mandt status_code = 'IP' status_description = 'In Progress' )
    ( client = sy-mandt status_code = 'PE' status_description = 'Pending' )
    ( client = sy-mandt status_code = 'CO' status_description = 'Clompleted' )
    ( client = sy-mandt status_code = 'CL' status_description = 'Closed' )
    ( client = sy-mandt status_code = 'CN' status_description = 'Canceled' ) ).

    lt_priority = VALUE #( ( client = sy-mandt priority_code = 'H' priority_description = 'High' )
    ( client = sy-mandt priority_code = 'M' priority_description = 'Medium' )
    ( client = sy-mandt priority_code = 'L' priority_description = 'Low' )  ).

    INSERT zdt_status_mr FROM TABLE @lt_status.

    INSERT zdt_priority_mr FROM TABLE @lt_priority.

    COMMIT WORK.

    out->write( 'Find ecarga inicial' ).
  ENDMETHOD.
ENDCLASS.
