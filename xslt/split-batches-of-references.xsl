<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet exclude-result-prefixes="#all" version="3.0" xmlns:tss="http://www.thirdstreetsoftware.com/SenteXML-1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    xmlns:bib="http://purl.org/net/biblio#"
    xmlns:dcterms="http://purl.org/dc/terms/">

    <xsl:output encoding="UTF-8" indent="yes" method="xml" omit-xml-declaration="no" version="1.0"/>

    <!-- identity transform -->
    <xsl:template match="node() | @*">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()"/>
        </xsl:copy>
    </xsl:template>

    <xsl:param name="p_batch-size" select="10"/>
    <xsl:variable name="v_file-name_input">
        <xsl:variable name="v_temp" select="tokenize(base-uri(), '/')[last()]"/>
        <xsl:value-of select="replace($v_temp, '^(.+?)(\..*)*$', '$1')"/>
    </xsl:variable>
    <xsl:variable name="v_url-file" select="base-uri()"/>
    <xsl:variable name="v_url-base" select="replace($v_url-file, '^(.+)/([^/]+?)$', '$1')"/>
    

    <xsl:template match="tss:references">
        <xsl:param name="p_onset" select="1"/>
        <xsl:param name="p_batch" select="1"/>
        <xsl:variable name="v_terminus" select="$p_onset + $p_batch-size -1"/>
        <xsl:message>
            <xsl:text>there are </xsl:text>
            <xsl:value-of select="ceiling(count(element()) div $p_batch-size)"/>
            <xsl:text> batches</xsl:text>
        </xsl:message>
        <!-- current batch -->
        <xsl:message>
            <xsl:text>saving batch no. </xsl:text>
            <xsl:value-of select="$p_batch"/>
        </xsl:message>
        <xsl:result-document href="{concat($v_url-base, '/batch/', $v_file-name_input, '_', $p_onset, '-', $v_terminus, '.TSS.xml')}">
            <xsl:element name="tss:senteContainer">
                <xsl:apply-templates select="ancestor::tss:senteContainer/@*"/>
                <xsl:element name="tss:library">
                    <xsl:element name="tss:references">
                        <xsl:apply-templates select="element()[position() &gt;= $p_onset][position() &lt;= $v_terminus]"/>
                    </xsl:element>
                </xsl:element>
            </xsl:element>
        </xsl:result-document>
        <!-- next batch -->
        <!-- check if there is anything left -->
        <xsl:if test="element()[position() gt $v_terminus]">
            <xsl:message>
                <xsl:text>there is another batch</xsl:text>
            </xsl:message>
            <xsl:apply-templates select=".">
                <xsl:with-param name="p_onset" select="$p_onset + $p_batch-size"/>
                <xsl:with-param name="p_batch" select="$p_batch + 1"/>
            </xsl:apply-templates>
        </xsl:if>
    </xsl:template>

    <xsl:template match="rdf:RDF">
        <xsl:param name="p_onset" select="1"/>
        <xsl:param name="p_batch" select="1"/>
        <xsl:variable name="v_terminus" select="$p_onset + $p_batch-size -1"/>
        <xsl:message>
            <xsl:text>there are </xsl:text>
            <xsl:value-of select="ceiling(count(element()[not(local-name() = 'Memo')]) div $p_batch-size)"/>
            <xsl:text> batches</xsl:text>
        </xsl:message>
        <!-- current batch -->
        <xsl:message>
            <xsl:text>saving batch no. </xsl:text>
            <xsl:value-of select="$p_batch"/>
        </xsl:message>
        <xsl:result-document href="{concat($v_url-base, '/batch/', $v_file-name_input, '_', $p_onset, '-', $v_terminus, '.Zotero.rdf')}">
            <xsl:copy>
                <xsl:apply-templates select="@*"/>
                        <!--<xsl:apply-templates select="element()[position() &gt;= $p_onset][position() &lt;= $v_terminus]"/>-->
                <xsl:for-each select="element()[not(local-name() = 'Memo')]">
                    <!-- number of preceding siblings must be >= $p_onset -->
                    <xsl:variable name="v_position" select="count(preceding-sibling::element()[not(local-name() = 'Memo')]) + 1"/>
                    <xsl:if test="$v_position &gt;= $p_onset and $v_position &lt;= $v_terminus">
                        <xsl:apply-templates select="."/>
                        <xsl:apply-templates select="following-sibling::bib:Memo[@rdf:about = current()/dcterms:isReferencedBy
                            /@rdf:resource]"/>
                    </xsl:if>
                </xsl:for-each>
            </xsl:copy>
        </xsl:result-document>
        <!-- next batch -->
        <!-- check if there is anything left -->
        <xsl:if test="count(element()[not(local-name() = 'Memo')]) gt $v_terminus">
            <xsl:message>
                <xsl:text>there is another batch</xsl:text>
            </xsl:message>
            <xsl:apply-templates select=".">
                <xsl:with-param name="p_onset" select="$p_onset + $p_batch-size"/>
                <xsl:with-param name="p_batch" select="$p_batch + 1"/>
            </xsl:apply-templates>
        </xsl:if>
    </xsl:template>

</xsl:stylesheet>
