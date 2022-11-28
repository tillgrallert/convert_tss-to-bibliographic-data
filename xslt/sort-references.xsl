<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet exclude-result-prefixes="#all" version="3.0" xmlns:bib="http://purl.org/net/biblio#" xmlns:dcterms="http://purl.org/dc/terms/" xmlns:link="http://purl.org/rss/1.0/modules/link/"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:tss="http://www.thirdstreetsoftware.com/SenteXML-1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

    <xsl:output encoding="UTF-8" indent="yes" method="xml" omit-xml-declaration="no" version="1.0"/>

    <!-- identity transform -->
    <xsl:template match="node() | @*">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="tss:references">
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <xsl:apply-templates select="tss:reference">
                <xsl:sort select="tss:publicationType/@name" order="ascending" />
                <xsl:sort select="tss:dates/tss:date[@type = 'Publication']/@year"/>
                <xsl:sort select="tss:dates/tss:date[@type = 'Modification']/@year"/>
                <xsl:sort select="tss:characteristics/tss:characteristic[@name = 'publicationTitle']" order="ascending"/>
            </xsl:apply-templates>
        </xsl:copy>
    </xsl:template>
</xsl:stylesheet>
