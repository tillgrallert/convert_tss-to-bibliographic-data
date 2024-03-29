<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
     xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
 xmlns:z="http://www.zotero.org/namespaces/export#"
 xmlns:bib="http://purl.org/net/biblio#"
 xmlns:foaf="http://xmlns.com/foaf/0.1/"
 xmlns:dc="http://purl.org/dc/elements/1.1/"
 xmlns:dcterms="http://purl.org/dc/terms/"
  xmlns:vcard="http://nwalsh.com/rdf/vCard#"
  xmlns:tss="http://www.thirdstreetsoftware.com/SenteXML-1.0" 
  xmlns:tei="http://www.tei-c.org/ns/1.0" 
  xmlns:html="http://www.w3.org/1999/xhtml"
  xmlns:prism="http://prismstandard.org/namespaces/1.2/basic/"
  xmlns:link="http://purl.org/rss/1.0/modules/link/"
  xmlns:oape="https://openarabicpe.github.io/ns"
    version="3.0">
    
    <xsl:output name="xml_no-indent" method="xml" indent="no" omit-xml-declaration="no" encoding="UTF-8"/>
    <xsl:output name="xml_indent" method="xml" indent="yes" omit-xml-declaration="no" encoding="UTF-8"/>
    <xsl:import href="convert_tss-to-zotero-rdf_functions.xsl"/>
    
    <xsl:param name="p_include-attachments" select="false()"/>
    <xsl:param name="p_include-notes" select="true()"/>
    <!-- values are: individual, summary, both -->
    <xsl:param name="p_note-type" select="'both'"/>
    <xsl:param name="p_debug" select="true()"/>
    
    <xsl:variable name="v_file-name" select="substring-before(tokenize(base-uri(),'/')[last()],'.TSS.xml')"/>
    
    <!-- debugging -->
    <xsl:template match="/">
        <xsl:result-document format="xml_indent" href="_output/{$v_file-name}.Zotero.rdf">
            <rdf:RDF>
                <xsl:apply-templates select="descendant::tss:reference" mode="m_tss-to-zotero-rdf"/>
            </rdf:RDF>
        </xsl:result-document>
    </xsl:template>
    
    <xsl:template match="tss:reference" mode="m_tss-to-zotero-rdf">
         <xsl:copy-of select="oape:bibliography-tss-to-zotero-rdf(., $p_include-attachments, $p_include-notes, $p_note-type)"/>
    </xsl:template>
</xsl:stylesheet>