@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'CDS Projection Incidentes Historico'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true
define view entity ZC_DT_INCT_H_MR
  as projection on ZDD_DT_INCT_H_MR
{
  key HisUuid,
  key IncUuid,
      HisId,
      PreviousStatus,
      NewStatus,
      Text,
      LocalCreatedBy,
      LocalCreatedAt,
      LocalLastChangedBy,
      LocalLastChangedAt,
      LastChangedAt,
      _Incident : redirected to parent ZC_DT_INCT_MR
}
