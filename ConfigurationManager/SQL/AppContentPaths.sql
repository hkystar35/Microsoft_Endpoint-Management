SELECT    DISTINCT APP.MANUFACTURER, APP.DISPLAYNAME, APP.SOFTWAREVERSION, DT.DISPLAYNAME AS DEPLOYMENTTYPENAME, DT.PRIORITYINLATESTAPP, DT.TECHNOLOGY,
V_CONTENTINFO.CONTENTSOURCE, V_CONTENTINFO.SOURCESIZE / 1024 as length_mb
FROM         DBO.FN_LISTDEPLOYMENTTYPECIS(1033) AS DT INNER JOIN
DBO.FN_LISTLATESTAPPLICATIONCIS(1033) AS APP ON DT.APPMODELNAME = APP.MODELNAME LEFT OUTER JOIN
V_CONTENTINFO ON DT.CONTENTID = V_CONTENTINFO.CONTENT_UNIQUEID
WHERE     (DT.ISLATEST = 1)