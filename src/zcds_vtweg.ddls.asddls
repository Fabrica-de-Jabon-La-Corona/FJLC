@AbapCatalog.sqlViewName: 'ZCDSVTWEG1'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@EndUserText.label: 'Ayuda para Canales de Distribución'
@UI.headerInfo.typeNamePlural: 'Canales de Distribución'

define view ZCDS_VTWEG1 as select from tvtw as a
    inner join tvtwt as b on b.vtweg = a.vtweg
{
    @Search.defaultSearchElement: true
    @Search.fuzzinessThreshold: 0.9
    key a.vtweg as CanalDistr,
    @Search.defaultSearchElement: true
    @Search.fuzzinessThreshold: 0.9
    b.vtext as Descripcion
}
where b.spras = 'S'
and a.hide = ''
