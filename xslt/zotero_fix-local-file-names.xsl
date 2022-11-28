<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet exclude-result-prefixes="#all" version="3.0" xmlns:bib="http://purl.org/net/biblio#" xmlns:dcterms="http://purl.org/dc/terms/" xmlns:link="http://purl.org/rss/1.0/modules/link/"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:tss="http://www.thirdstreetsoftware.com/SenteXML-1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:z="http://www.zotero.org/namespaces/export#">

    <xsl:output encoding="UTF-8" indent="yes" method="xml" omit-xml-declaration="no" version="1.0"/>

    <!-- identity transform -->
    <xsl:template match="node() | @*">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()"/>
        </xsl:copy>
    </xsl:template>
    <xsl:param name="p_replace-with" select="'-file_'"/>
    <xsl:template match="rdf:resource[parent::z:Attachment][following-sibling::z:linkMode = 2]/@rdf:resource">
        <xsl:attribute name="rdf:resource">
            <xsl:choose>
                <xsl:when test="matches(., '\s#\d+\.\w{3,4}$')">
                    <xsl:value-of select="replace(., '\s#(\d+\.\w{3,4})', concat($p_replace-with, '$1'))"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="."/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:attribute>
    </xsl:template>
</xsl:stylesheet>