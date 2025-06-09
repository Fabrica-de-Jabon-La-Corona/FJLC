@AbapCatalog.sqlViewName: 'ZCDSBUSIPARTNER'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@EndUserText.label: 'Catálogo de Clientes'
@UI.headerInfo.typeNamePlural: 'Catálogo de Clientes'
//@ObjectModel.transactionalProcessingDelegated: true

define view ZCDS_BUSIPARTNER 
//with parameters
//p_agente: vkgrp
as select from knvv as a
    inner join kna1 as b on b.kunnr = a.kunnr
    inner join adrc as c on c.addrnumber = b.adrnr
{
    @Search.defaultSearchElement: true
    @Search.fuzzinessThreshold: 0.9
    key a.vkgrp as Agente,
    a.vkorg as OrgVentas,
    a.vtweg as Canal,
    a.kunnr as Cliente,
    concat_with_space( b.name1, concat_with_space(b.name2, concat_with_space(b.name3, b.name4, 1), 1), 1) as Nombre,
    a.bzirk as ZonaVentas,
    a.vkbur as OficinaVentas,
    a.kvgr1 as Cadena,
    a.vwerk as CentroSuministrador,
    a.zterm as CondicionesPago,
    c.street as Calle,
    c.house_num1 as NumeroExterior,
    c.city1 as Colonia,
    c.city2 as Municipio,
    c.post_code1 as CodigoPostal,
    c.region as Estado,
    c.country as Pais,
    c.langu as Idioma    
}
where a.loevm = ''
and a.aufsd = ''
and a.lifsd = ''
and a.faksd = ''
//and a.vkgrp = $parameters.p_agente
