@Metadata.allowExtensions: true
@Metadata.ignorePropagatedAnnotations: true
@EndUserText.label: 'CDS Root Entity Incidentes'
@AccessControl.authorizationCheck: #NOT_REQUIRED
define root view entity ZC_DT_INCT_MR
  provider contract transactional_query
  as projection on ZR_DT_INCT_MR
{
  key IncUUID,
      IncidentID,
      Title,
      Description,
      Status,
      Priority,
      RespUser,
      CreationDate,
      ChangedDate,
      @Semantics: {
        user.createdBy: true
      }
      LocalCreatedBy,
      @Semantics: {
        systemDateTime.createdAt: true
      }
      LocalCreatedAt,
      @Semantics: {
        user.localInstanceLastChangedBy: true
      }
      LocalLastChangedBy,
      @Semantics: {
        systemDateTime.localInstanceLastChangedAt: true
      }
      LocalLastChangedAt,
      @Semantics: {
        systemDateTime.lastChangedAt: true
      }
      LastChangedAt,
      _History : redirected to composition child ZC_DT_INCT_H_MR
}
