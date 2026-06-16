CLASS lhc_Incident DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR Incident RESULT result.

    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR Incident RESULT result.
    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR Incident RESULT result.

    METHODS: changeStatus FOR MODIFY
      IMPORTING keys FOR ACTION Incident~changeStatus RESULT result,
      setDefaultValues FOR DETERMINE ON MODIFY
        IMPORTING keys FOR Incident~setDefaultValues,
      setDefaultHistory FOR DETERMINE ON SAVE
        IMPORTING keys FOR Incident~setDefaultHistory,
      setHistory FOR MODIFY
        IMPORTING keys FOR ACTION Incident~setHistory,
      get_history_index EXPORTING ev_incuuid      TYPE sysuuid_x16
                        RETURNING VALUE(rv_index) TYPE zde_h_inc_id_mr,
      validateFieldsMandatory FOR VALIDATE ON SAVE
        IMPORTING keys FOR Incident~validateFieldsMandatory,
      validateResponsible FOR VALIDATE ON SAVE
        IMPORTING keys FOR Incident~validateResponsible.

ENDCLASS.

CLASS lhc_Incident IMPLEMENTATION.

  METHOD get_instance_authorizations.
  ENDMETHOD.

  METHOD get_global_authorizations.
  ENDMETHOD.

" Se habilitan botones y asociaciones
  METHOD get_instance_features.

    DATA lv_history_index TYPE zde_h_inc_id_mr.
    READ ENTITIES OF zr_dt_inct_mr IN LOCAL MODE
       ENTITY Incident
         FIELDS ( Status RespUser )
         WITH CORRESPONDING #( keys )
       RESULT DATA(incidents)
       FAILED failed.

    IF sy-subrc EQ 0.
      DATA(lv_create_action) = lines( incidents ).

      DATA(lv_user) = cl_abap_context_info=>get_user_technical_name( ).

      IF lv_create_action EQ 1.
        lv_history_index = get_history_index( IMPORTING ev_incuuid = incidents[ 1 ]-IncUUID ).
      ELSE.
        lv_history_index = 1.
      ENDIF.

      result = VALUE #( FOR incident IN incidents
                            ( %tky                   = incident-%tky
                              %action-ChangeStatus   = COND #( WHEN incident-Status = mc_status-completed OR
                                                                    incident-Status = mc_status-closed    OR
                                                                    incident-Status = mc_status-canceled  OR
                                                                    lv_history_index = 0
                                                               THEN  if_abap_behv=>fc-o-disabled
                                                               ELSE
                                                               "Se habilita si es un admin
                                                               COND #( WHEN lv_user EQ c_admin
                                                               THEN if_abap_behv=>fc-o-enabled
                                                               "Se habilita si es el responsable
                                                               ELSE COND #( WHEN lv_user EQ incident-RespUser
                                                               THEN if_abap_behv=>fc-o-enabled
                                                               ELSE if_abap_behv=>fc-o-disabled ) )
                                                                )

                              %assoc-_History       = COND #( WHEN incident-Status = mc_status-completed OR
                                                                   incident-Status = mc_status-closed    OR
                                                                   incident-Status = mc_status-canceled  OR
                                                                   lv_history_index = 0
                                                              THEN if_abap_behv=>fc-o-disabled
                                                              ELSE if_abap_behv=>fc-o-enabled )
                            ) ).

    ENDIF.
  ENDMETHOD.

"Metodo para validar cambio de estatus
  METHOD changeStatus.

    DATA: lt_updated_root_entity TYPE TABLE FOR UPDATE zr_dt_inct_mr,
          lt_association_entity  TYPE TABLE FOR CREATE zr_dt_inct_mr\_History,
          lv_new_status          TYPE zde_status_mr,
          lv_resp_user           TYPE zde_usr_resp_mr,
          lv_text                TYPE zde_obs_mr,
          lv_exception           TYPE string,
          lv_error               TYPE c,
          ls_incident_history    TYPE zdt_inct_h_mr,
          lv_max_his_id          TYPE zde_h_inc_id_mr,
          lv_wrong_status        TYPE zde_status_mr.

    READ ENTITIES OF zr_dt_inct_mr IN LOCAL MODE
         ENTITY Incident
         ALL FIELDS WITH CORRESPONDING #( keys )
         RESULT DATA(incidents)
         FAILED failed.


    LOOP AT incidents ASSIGNING FIELD-SYMBOL(<incident>).

      lv_new_status = keys[ KEY id %tky = <incident>-%tky ]-%param-status.
      lv_resp_user = keys[ KEY id %tky = <incident>-%tky ]-%param-RespUser.

      IF lv_new_status EQ mc_status-inprogress AND lv_resp_user IS INITIAL.
        APPEND VALUE #(
            %tky = <incident>-%tky
            %msg = new_message_with_text(
                          severity = if_abap_behv_message=>severity-error
                          text = 'Responsable no puede estar vacío' )
                      ) TO reported-incident.
        RETURN.
      ENDIF.

      IF <incident>-Status EQ mc_status-pending AND lv_new_status EQ mc_status-closed OR
         <incident>-Status EQ mc_status-pending AND lv_new_status EQ mc_status-completed.

        APPEND VALUE #( %tky = <incident>-%tky ) TO failed-incident.

        lv_wrong_status = lv_new_status.

        APPEND VALUE #( %tky = <incident>-%tky
                        %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                                        text     = |'Status actual no permite actualizar a estatus '{ lv_new_status }| )
                         ) TO reported-incident.
        lv_error = abap_true.
        EXIT.
      ENDIF.

      IF lv_resp_user IS INITIAL AND <incident>-RespUser IS NOT INITIAL.
        lv_resp_user = <incident>-RespUser.
      ENDIF.

      APPEND VALUE #( %tky = <incident>-%tky
                      ChangedDate = cl_abap_context_info=>get_system_date( )
                      Status = lv_new_status
                      RespUser = lv_resp_user
                      ) TO lt_updated_root_entity.


      lv_text = keys[ KEY id %tky = <incident>-%tky ]-%param-text.

      lv_max_his_id = get_history_index(
                  IMPORTING
                    ev_incuuid = <incident>-IncUUID ).

      IF lv_max_his_id IS INITIAL.
        ls_incident_history-his_id = 1.
      ELSE.
        ls_incident_history-his_id = lv_max_his_id + 1.
      ENDIF.

      ls_incident_history-new_status = lv_new_status.
      ls_incident_history-text = lv_text.

      TRY.
          ls_incident_history-inc_uuid = cl_system_uuid=>create_uuid_x16_static( ).
        CATCH cx_uuid_error INTO DATA(lo_error).
          lv_exception = lo_error->get_text(  ).
      ENDTRY.

      IF ls_incident_history-his_id IS NOT INITIAL.
*
        APPEND VALUE #( %tky = <incident>-%tky
                        %target = VALUE #( (  HisUUID = ls_incident_history-inc_uuid
                                              IncUUID = <incident>-IncUUID
                                              HisID = ls_incident_history-his_id
                                              PreviousStatus = <incident>-Status
                                              NewStatus = ls_incident_history-new_status
                                              Text = ls_incident_history-text ) )
                                               ) TO lt_association_entity.
      ENDIF.
    ENDLOOP.
    UNASSIGN <incident>.

    CHECK lv_error IS INITIAL.


    MODIFY ENTITIES OF zr_dt_inct_mr IN LOCAL MODE
    ENTITY Incident
    UPDATE  FIELDS ( ChangedDate
                     Status
                     RespUser )
    WITH lt_updated_root_entity.

    FREE incidents.

    MODIFY ENTITIES OF zr_dt_inct_mr IN LOCAL MODE
     ENTITY Incident
     CREATE BY \_History FIELDS ( HisUUID
                                  IncUUID
                                  HisID
                                  PreviousStatus
                                  NewStatus
                                  Text )
        AUTO FILL CID
        WITH lt_association_entity
     MAPPED mapped
     FAILED failed
     REPORTED reported.


    READ ENTITIES OF zr_dt_inct_mr IN LOCAL MODE
    ENTITY Incident
    ALL FIELDS WITH CORRESPONDING #( keys )
    RESULT incidents
    FAILED failed.


    result = VALUE #( FOR incident IN incidents ( %tky = incident-%tky
                                                  %param = incident ) ).
  ENDMETHOD.

"Carga valores por default: Inc Id, Fecha Creacion y Estatus inicial
  METHOD setDefaultValues.

    READ ENTITIES OF zr_dt_inct_mr IN LOCAL MODE
       ENTITY Incident
       FIELDS ( CreationDate
                Status ) WITH CORRESPONDING #( keys )
       RESULT DATA(lt_incidents).

    IF sy-subrc EQ 0.
      DELETE lt_incidents WHERE CreationDate IS NOT INITIAL.

      CHECK lt_incidents IS NOT INITIAL.

      SELECT FROM zdt_inct_mr
        FIELDS MAX( incident_id )
        WHERE incident_id IS NOT NULL
        INTO @DATA(lv_max_id).

      lv_max_id += 1.

      MODIFY ENTITIES OF zr_dt_inct_mr IN LOCAL MODE
        ENTITY Incident
        UPDATE
        FIELDS ( IncidentID
                 CreationDate
                 Status )
        WITH VALUE #(  FOR ls_incident IN lt_incidents ( %tky = ls_incident-%tky
                                                   IncidentID = lv_max_id
                                                   CreationDate = cl_abap_context_info=>get_system_date( )
                                                   Status       = mc_status-open )  ).

    ENDIF.

  ENDMETHOD.


  METHOD setDefaultHistory.
    MODIFY ENTITIES OF zr_dt_inct_mr IN LOCAL MODE
    ENTITY Incident
    EXECUTE setHistory
       FROM CORRESPONDING #( keys ).
  ENDMETHOD.

  METHOD setHistory.

    DATA: lt_association_entity TYPE TABLE FOR CREATE zr_dt_inct_mr\_History,
          lv_exception          TYPE string,
          ls_incident_history   TYPE zdt_inct_h_mr,
          lv_max_his_id         TYPE zde_h_inc_id_mr.


    READ ENTITIES OF zr_dt_inct_mr IN LOCAL MODE
         ENTITY Incident
         ALL FIELDS WITH CORRESPONDING #( keys )
         RESULT DATA(lt_incidents).


    LOOP AT lt_incidents ASSIGNING FIELD-SYMBOL(<incident>).
      lv_max_his_id = get_history_index( IMPORTING ev_incuuid = <incident>-IncUUID ).

      IF lv_max_his_id IS INITIAL.
        ls_incident_history-his_id = 1.
      ELSE.
        ls_incident_history-his_id = lv_max_his_id + 1.
      ENDIF.

      TRY.
          ls_incident_history-inc_uuid = cl_system_uuid=>create_uuid_x16_static( ).
        CATCH cx_uuid_error INTO DATA(lo_error).
          lv_exception = lo_error->get_text(  ).
      ENDTRY.

      IF ls_incident_history-his_id IS NOT INITIAL.
        APPEND VALUE #( %tky = <incident>-%tky
                        %target = VALUE #( (  HisUUID = ls_incident_history-inc_uuid
                                              IncUUID = <incident>-IncUUID
                                              HisID = ls_incident_history-his_id
                                              NewStatus = <incident>-Status
                                              Text = 'First Incident' ) )
                                               ) TO lt_association_entity.
      ENDIF.
    ENDLOOP.
    UNASSIGN <incident>.

    FREE lt_incidents.

    MODIFY ENTITIES OF zr_dt_inct_mr IN LOCAL MODE
     ENTITY Incident
     CREATE BY \_History FIELDS ( HisUUID
                                  IncUUID
                                  HisID
                                  PreviousStatus
                                  NewStatus
                                  Text )
        AUTO FILL CID
        WITH lt_association_entity.

  ENDMETHOD.

  METHOD get_history_index.

    SELECT FROM zdt_inct_h_mr
      FIELDS MAX( his_id ) AS max_his_id
      WHERE inc_uuid EQ @ev_incuuid AND
            his_uuid IS NOT NULL
      INTO @rv_index.
  ENDMETHOD.

"Valida campos mandatorios Titulo,Descripcion y Prioridad
  METHOD validateFieldsMandatory.

    READ ENTITIES OF zr_dt_inct_mr IN LOCAL MODE
       ENTITY Incident
       FIELDS ( Title Description Priority )
       WITH CORRESPONDING #( keys )
       RESULT DATA(lt_incidents).

    CHECK lt_incidents IS NOT INITIAL.

    LOOP AT lt_incidents INTO DATA(ls_incident).
      IF ls_incident-Title IS INITIAL OR ls_incident-Description IS INITIAL OR ls_incident-Priority IS INITIAL.
        APPEND VALUE #( %tky = ls_incident-%tky ) TO failed-incident.
        APPEND VALUE #( %tky = ls_incident-%tky
                        %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                                      text     = 'Campos: Titulo\Descripcion\Prioridad son obligatorios.' )
                      ) TO reported-incident.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.
"Valida campo responsable qu eno este vacio si Status = IP
  METHOD validateResponsible.

    READ ENTITIES OF zr_dt_inct_mr IN LOCAL MODE
         ENTITY Incident
         FIELDS ( RespUser Status )
         WITH CORRESPONDING #( keys )
         RESULT DATA(lt_incidents).

    CHECK lt_incidents IS NOT INITIAL.

    LOOP AT lt_incidents INTO DATA(ls_incident).
      IF ls_incident-RespUser IS INITIAL AND ls_incident-Status EQ mc_status-inprogress.
        APPEND VALUE #( %tky = ls_incident-%tky ) TO failed-incident.
        APPEND VALUE #( %tky = ls_incident-%tky
                        %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                                      text     = 'Campos Responsable no puede estar vacio' )
                      ) TO reported-incident.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
