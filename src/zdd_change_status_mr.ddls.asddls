@EndUserText.label: 'CDS Abstracta Change Status'
define abstract entity zdd_change_status_mr
{
  @EndUserText.label: 'New Status'
  @Consumption.valueHelpDefinition: [ {
      entity.name: 'zdd_status_vh_mr',
      entity.element: 'StatusCode',
      useForValidation: true
  } ]
  status      : zde_status_mr;

  @EndUserText.label: 'Observation'
  text        : zde_obs_mr;

  @EndUserText.label: 'Responsable'
  RespUser : zde_usr_resp_mr;

}
