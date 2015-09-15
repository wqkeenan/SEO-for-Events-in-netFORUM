<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xlink="http://www.w3.org/1999/xhref" xmlns:xs="http://www.w3.org/2001/XMLSchema"
    exclude-result-prefixes="xs xml xlink" version="1.0">
    
    <xsl:output method="html" indent="yes"/>
    
    <xsl:param name="HttpServerPath"/>
    
    <xsl:include href="lib/json-ld.lib.xsl"/>
    
    <xsl:template match="/">
        <xsl:if test="//@itemtype">
            <script type="application/ld+json">  
                <xsl:apply-templates select="." mode="json-ld"/>
            </script>
        </xsl:if>
    </xsl:template>
    
</xsl:stylesheet>
