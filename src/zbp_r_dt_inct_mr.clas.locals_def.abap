*"* use this source file for any type of declarations (class
*"* definitions, interfaces or type declarations) you need for
*"* components in the private section

CONSTANTS: BEGIN OF mc_status,
                 open        TYPE zde_status_mr VALUE 'OP',
                 inprogress TYPE zde_status_mr VALUE 'IP',
                 pending     TYPE zde_status_mr VALUE 'PE',
                 completed   TYPE zde_status_mr VALUE 'CO',
                 closed      TYPE zde_status_mr VALUE 'CL',
                 canceled    TYPE zde_status_mr VALUE 'CN',
               END OF mc_status,

            c_admin    TYPE zde_usr_resp_mr VALUE 'CB9980000670'. " ID de administrador
