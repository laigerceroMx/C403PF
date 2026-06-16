@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
@EndUserText.label: 'CDS Root Entity Incidentes'
define root view entity ZR_DT_INCT_MR
  as select from zdt_inct_mr as Incident
  composition [0..*] of ZDD_DT_INCT_H_MR as _History
{
  key inc_uuid as IncUUID,
  incident_id as IncidentID,
  title as Title,
  description as Description,
  status as Status,
  priority as Priority,
  resp_user as RespUser,
  creation_date as CreationDate,
  changed_date as ChangedDate,
  @Semantics.user.createdBy: true
  local_created_by as LocalCreatedBy,
  @Semantics.systemDateTime.createdAt: true
  local_created_at as LocalCreatedAt,
  @Semantics.user.localInstanceLastChangedBy: true
  local_last_changed_by as LocalLastChangedBy,
  @Semantics.systemDateTime.localInstanceLastChangedAt: true
  local_last_changed_at as LocalLastChangedAt,
  @Semantics.systemDateTime.lastChangedAt: true
  last_changed_at as LastChangedAt,
  _History
}
