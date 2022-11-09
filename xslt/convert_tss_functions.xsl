<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:tss="http://www.thirdstreetsoftware.com/SenteXML-1.0"
    xmlns:mods="http://www.loc.gov/mods/v3" 
    xmlns:html="http://www.w3.org/1999/xhtml"
    xmlns="http://www.loc.gov/mods/v3"  
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns:oape="https://openarabicpe.github.io/ns"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xpath-default-namespace="http://www.loc.gov/mods/v3"
    exclude-result-prefixes="#all"
    version="3.0">
    <xsl:output method="xml" encoding="UTF-8" indent="yes" omit-xml-declaration="no" version="1.0"/>
    
    <xsl:variable name="v_css-div" select="'display: block; border: 1px solid black;'"/>
     <xsl:function name="oape:bibliography-tss-note-to-html">
        <!-- expects a <tss:note> as input -->
        <xsl:param name="tss_note"/>
         <![CDATA[<div style="]]><xsl:value-of select="$v_css-div"/><![CDATA[background-color:]]><xsl:apply-templates select="$tss_note/@color" mode="m_tss-notes-to-html"/><![CDATA[">]]>
         <!-- add a first line: sorting and display in Zotero -->
         <xsl:apply-templates select="$tss_note" mode="m_tss-note-summary"/>
        <xsl:apply-templates select="$tss_note/tss:pages" mode="m_tss-notes-to-html"/>
        <xsl:apply-templates select="$tss_note/tss:title" mode="m_tss-notes-to-html"/>
        <xsl:apply-templates select="$tss_note/tss:quotation" mode="m_tss-notes-to-html"/>
        <xsl:apply-templates select="$tss_note/tss:comment" mode="m_tss-notes-to-html"/>
         <![CDATA[</div>]]>
    </xsl:function>
    
    <xsl:template match="tss:note" mode="m_tss-note-summary">
        <![CDATA[<span>]]>
        <xsl:if test="tss:pages != ''">
            <xsl:value-of select="tss:pages"/>
<!--            <xsl:value-of select="count(preceding-sibling::tss:note) + 1"/>-->
            <xsl:text>: </xsl:text>
        </xsl:if>
        <xsl:choose>
            <xsl:when test="tss:title">
                <xsl:value-of select=" substring(normalize-space(tss:title), 1, 50)"/>
            </xsl:when>
            <xsl:when test="tss:quotation">
                <xsl:text>"</xsl:text><xsl:value-of select="substring(normalize-space(tss:quotation), 1, 50)"/><xsl:text>"</xsl:text>
            </xsl:when>
        </xsl:choose>
        <![CDATA[</span><br/>]]>
    </xsl:template>
    
    <xsl:template match="tss:title" mode="m_tss-notes-to-html">
        <![CDATA[<h1>]]><xsl:text># </xsl:text><xsl:apply-templates mode="m_mark-up"/><![CDATA[</h1>]]>
    </xsl:template>
    <xsl:template match="tss:pages[.!='']" mode="m_tss-notes-to-html">
        <![CDATA[<p>]]><xsl:text>(</xsl:text>
        <xsl:if test="matches(.,'^\d')">
            <xsl:text>p.</xsl:text>
        </xsl:if>
        <xsl:apply-templates/><xsl:text>)</xsl:text><![CDATA[</p>]]>
    </xsl:template>
    <xsl:template match="tss:quotation" mode="m_tss-notes-to-html">
        <![CDATA[<blockquote style="background-color:]]><xsl:apply-templates select="parent::tss:note/@color" mode="m_tss-notes-to-html"/><![CDATA[">]]>
        <![CDATA[<p>]]><xsl:text>></xsl:text><xsl:apply-templates mode="m_mark-up"/><![CDATA[</p>]]>
        <![CDATA[</blockquote>]]>
    </xsl:template>
    <!-- this was an aborted trial -->
    <xsl:template match="tss:quotation">
        <![CDATA[<blockquote style="]]><xsl:value-of select="parent::tss:note/@style"/><![CDATA[">]]>
        <![CDATA[<p>]]><xsl:text>></xsl:text><xsl:apply-templates mode="m_mark-up"/><![CDATA[</p>]]>
        <![CDATA[</blockquote>]]>
    </xsl:template>
    <xsl:template match="tss:comment" mode="m_tss-notes-to-html">
        <![CDATA[<p>]]><xsl:apply-templates mode="m_mark-up"/><![CDATA[</p>]]>
    </xsl:template>
    
    <xsl:template match="@color" mode="m_tss-notes-to-html">
        <xsl:choose>
            <xsl:when test=". = 'yellow'">
                <xsl:text>#FFF9D6</xsl:text>
            </xsl:when>
            <xsl:when test=". = 'orange'">
                <xsl:text>#FDEADB</xsl:text>
            </xsl:when>
            <xsl:when test=". = 'red'">
                <xsl:text>#FFDDDD</xsl:text>
            </xsl:when>
            <xsl:when test=". = 'purple'">
                <xsl:text>#E9DCEB</xsl:text>
            </xsl:when>
            <xsl:when test=". = 'blue'">
                <xsl:text>#E0ECF4</xsl:text>
            </xsl:when>
            <xsl:when test=". = 'green'">
                <xsl:text>#E3EDE7</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>#DCD9C7</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <!-- map reference types -->
    <xsl:variable name="v_reference-types">
        <tei:listNym>
            <tei:nym>
                <tei:form n="tss">Archival Book Chapter</tei:form>
                <tei:form n="zotero">bookSection</tei:form>
                <tei:form n="marcgt"></tei:form>
                <tei:form n="bib">BookSection</tei:form>
                <tei:form n="biblatex"></tei:form>
                <tei:form n="csl"></tei:form>
            </tei:nym>
            <tei:nym>
                <tei:form n="tss">Archival File</tei:form>
                <tei:form n="zotero">manuscript</tei:form>
                <tei:form n="marcgt"></tei:form>
                <tei:form n="bib">Manuscript</tei:form>
                <tei:form n="biblatex"></tei:form>
                <tei:form n="csl">manuscript</tei:form>
            </tei:nym>
            <tei:nym>
                <tei:form n="tss">Archival Journal Entry</tei:form>
                <tei:form n="zotero">manuscript</tei:form>
                <tei:form n="marcgt"></tei:form>
                <tei:form n="bib">Manuscript</tei:form>
                <tei:form n="biblatex"></tei:form>
                <tei:form n="csl">manuscript</tei:form>
            </tei:nym>
            <tei:nym>
                <tei:form n="tss">Archival Letter</tei:form>
                <tei:form n="zotero">letter</tei:form>
                <tei:form n="marcgt">letter</tei:form>
                <tei:form n="bib">Letter</tei:form>
                <tei:form n="biblatex"></tei:form>
                <tei:form n="csl">personal_communication</tei:form>
            </tei:nym>
            <tei:nym>
                <tei:form n="tss">Archival Material</tei:form>
                <tei:form n="zotero">manuscript</tei:form>
                <tei:form n="marcgt"></tei:form>
                <tei:form n="bib">Manuscript</tei:form>
                <tei:form n="biblatex"></tei:form>
                <tei:form n="csl">manuscript</tei:form>
            </tei:nym>
            <tei:nym>
                <tei:form n="tss">Archival Periodical</tei:form>
                <tei:form n="zotero">newspaperArticle</tei:form>
                <tei:form n="marcgt"></tei:form>
                <tei:form n="bib">Article</tei:form>
                <tei:form n="biblatex">article</tei:form>
                <tei:form n="csl">article-newspaper</tei:form>
            </tei:nym>
            <tei:nym>
                <tei:form n="tss">Archival Periodical Article</tei:form>
                <tei:form n="zotero">magazineArticle</tei:form>
                <tei:form n="marcgt"></tei:form>
                <tei:form n="bib">Article</tei:form>
                <tei:form n="biblatex">article</tei:form>
                <tei:form n="csl">article-magazine</tei:form>
            </tei:nym>
            <tei:nym>
                <tei:form n="tss">Bill</tei:form>
                <tei:form n="zotero">bill</tei:form>
                <tei:form n="marcgt"></tei:form>
                <tei:form n="bib">Legislation</tei:form>
                <tei:form n="biblatex"></tei:form>
                <tei:form n="csl">bill</tei:form>
            </tei:nym>
            <tei:nym>
                <tei:form n="tss">Book</tei:form>
                <tei:form n="zotero">book</tei:form>
                <tei:form n="marcgt">book</tei:form>
                <tei:form n="bib">Book</tei:form>
                <tei:form n="biblatex">mvbook</tei:form>
                <tei:form n="csl">book</tei:form>
            </tei:nym>
            <tei:nym>
                <tei:form n="tss">Book Chapter</tei:form>
                <tei:form n="zotero">bookSection</tei:form>
                <tei:form n="marcgt"></tei:form>
                <tei:form n="bib">BookSection</tei:form>
                <tei:form n="biblatex"></tei:form>
                <tei:form n="csl">chapter</tei:form>
            </tei:nym>
            <tei:nym>
                <tei:form n="tss">CD/DVD</tei:form>
                <tei:form n="zotero">computerProgram</tei:form>
                <tei:form n="marcgt"></tei:form>
                <tei:form n="bib">Data</tei:form>
                <tei:form n="biblatex"></tei:form>
                <tei:form n="csl"></tei:form>
            </tei:nym>
            <tei:nym>
                <tei:form n="tss">Computer Software</tei:form>
                <tei:form n="zotero">computerProgram</tei:form>
                <tei:form n="marcgt"></tei:form>
                <tei:form n="bib">Data</tei:form>
                <tei:form n="biblatex"></tei:form>
                <tei:form n="csl"></tei:form>
            </tei:nym>
            <tei:nym>
                <tei:form n="tss">Conference Proceedings</tei:form>
                <tei:form n="zotero">book</tei:form>
                <tei:form n="marcgt">book</tei:form>
                <tei:form n="bib">Book</tei:form>
                <tei:form n="biblatex">mvbook</tei:form>
                <tei:form n="csl">book</tei:form>
            </tei:nym>
            <tei:nym>
                <tei:form n="tss">Edited Book</tei:form>
                <tei:form n="zotero">book</tei:form>
                <tei:form n="marcgt">book</tei:form>
                <tei:form n="bib">Book</tei:form>
                <tei:form n="biblatex">mvbook</tei:form>
                <tei:form n="csl">book</tei:form>
            </tei:nym>
            <tei:nym>
                <tei:form n="tss">Electronic Citation</tei:form>
                <tei:form n="zotero">webpage</tei:form>
                <tei:form n="marcgt"></tei:form>
                <tei:form n="bib">Document</tei:form>
                <tei:form n="biblatex"></tei:form>
                <tei:form n="csl">webpage</tei:form>
            </tei:nym>
            <tei:nym>
                <tei:form n="tss">Journal Article</tei:form>
                <tei:form n="zotero">journalArticle</tei:form>
                <tei:form n="marcgt"></tei:form>
                <tei:form n="bib">Article</tei:form>
                <tei:form n="biblatex">article</tei:form>
                <tei:form n="csl">article-journal</tei:form>
            </tei:nym>
            <tei:nym>
                <tei:form n="tss">Magazine Article</tei:form>
                <tei:form n="zotero">magazineArticle</tei:form>
                <tei:form n="marcgt"></tei:form>
                <tei:form n="bib">Article</tei:form>
                <tei:form n="biblatex">article</tei:form>
                <tei:form n="csl">article-magazine</tei:form>
            </tei:nym>
            <tei:nym>
                <tei:form n="tss">Manuscript</tei:form>
                <tei:form n="zotero">manuscript</tei:form>
                <tei:form n="marcgt"></tei:form>
                <tei:form n="bib">Manuscript</tei:form>
                <tei:form n="biblatex"></tei:form>
                <tei:form n="csl">manuscript</tei:form>
            </tei:nym>
            <tei:nym>
                <tei:form n="tss">Maps</tei:form>
                <tei:form n="zotero">map</tei:form>
                <tei:form n="marcgt"></tei:form>
                <tei:form n="bib">Image</tei:form>
                <tei:form n="biblatex"></tei:form>
                <tei:form n="csl">map</tei:form>
            </tei:nym>
            <tei:nym>
                <tei:form n="tss">Motion Picture</tei:form>
                <tei:form n="zotero"></tei:form>
                <tei:form n="marcgt"></tei:form>
                <tei:form n="bib"></tei:form>
                <tei:form n="biblatex"></tei:form>
                <tei:form n="csl"></tei:form>
            </tei:nym>
            <tei:nym>
                <tei:form n="tss">Newspaper article</tei:form>
                <tei:form n="zotero">newspaperArticle</tei:form>
                <tei:form n="marcgt"></tei:form>
                <tei:form n="bib">Article</tei:form>
                <tei:form n="biblatex">article</tei:form>
                <tei:form n="csl">article-newspaper</tei:form>
            </tei:nym>
            <tei:nym>
                <tei:form n="tss">Other</tei:form>
                <tei:form n="zotero"></tei:form>
                <tei:form n="marcgt"></tei:form>
                <tei:form n="bib"></tei:form>
                <tei:form n="biblatex"></tei:form>
                <tei:form n="csl"></tei:form>
            </tei:nym>
            <tei:nym>
                <tei:form n="tss">Photograph</tei:form>
                <tei:form n="zotero">artwork</tei:form>
                <tei:form n="marcgt"></tei:form>
                <tei:form n="bib"></tei:form>
                <tei:form n="biblatex"></tei:form>
                <tei:form n="csl"></tei:form>
            </tei:nym>
            <tei:nym>
                <tei:form n="tss">Presentation</tei:form>
                <tei:form n="zotero">presentation</tei:form>
                <tei:form n="marcgt"></tei:form>
                <tei:form n="bib">ConferenceProceedings</tei:form>
                <tei:form n="biblatex"></tei:form>
                <tei:form n="csl"></tei:form>
            </tei:nym>
            <tei:nym>
                <tei:form n="tss">Thesis type</tei:form>
                <tei:form n="zotero">thesis</tei:form>
                <tei:form n="marcgt"></tei:form>
                <tei:form n="bib">Thesis</tei:form>
                <tei:form n="biblatex"></tei:form>
                <tei:form n="csl">thesis</tei:form>
            </tei:nym>
            <tei:nym>
                <tei:form n="tss">Web Page</tei:form>
                <tei:form n="zotero">webpage</tei:form>
                <tei:form n="marcgt"></tei:form>
                <tei:form n="bib">Document</tei:form>
                <tei:form n="biblatex"></tei:form>
                <tei:form n="csl">webpage</tei:form>
            </tei:nym>
        </tei:listNym>
    </xsl:variable>
    
    <!-- this function checks, if one needs to switch volume and issue information based on a periodical's title -->
    <xsl:function name="oape:bibliography-tss-switch-volume-and-issue">
        <xsl:param name="tss_reference"/>
        <xsl:variable name="v_title-short" select=" lower-case($tss_reference/descendant::tss:characteristic[@name = 'Short Titel'])"/>
        <xsl:choose>
            <xsl:when test="$v_title-short = ('lisān')">
                <xsl:copy-of select="true()"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy-of select="false()"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <!-- HTML mark-up inside abstracts and notes? -->
    <xsl:template match="html:*" mode="m_tss-to-zotero-rdf"/>
    <xsl:template match="tss:characteristic" mode="m_mark-up">
        <xsl:choose>
            <xsl:when test="html:br">
                <xsl:for-each-group select="child::node()" group-starting-with="html:br">
                    <!--<xsl:message>
                        <xsl:value-of select="current-group()"/>
                    </xsl:message>-->
                    <![CDATA[<p>]]><xsl:apply-templates select="current-group()" mode="m_mark-up"/><![CDATA[</p>]]>
                </xsl:for-each-group>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates mode="m_mark-up"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <!-- in conjunction with the above template this will introduce unnecessary line breaks -->
    <xsl:template match="html:br" mode="m_mark-up">
        <![CDATA[<br/>]]>
    </xsl:template>
    <xsl:template match="html:*" mode="m_mark-up">
        <![CDATA[<]]><xsl:value-of select="replace(name(),'html:','')"/><![CDATA[>]]>
        <xsl:apply-templates mode="m_mark-up"/>
        <![CDATA[</]]><xsl:value-of select="replace(name(),'html:','')"/><![CDATA[>]]>
    </xsl:template>
    <xsl:template match="tei:*" mode="m_mark-up">
        <![CDATA[<]]><xsl:value-of select="name()"/>
        <xsl:if test="@*">
            <xsl:apply-templates select="@*" mode="m_mark-up"/>
        </xsl:if>
        <xsl:choose>
            <xsl:when test=".=''">
                <xsl:value-of select="'/&gt;'" disable-output-escaping="no"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="'&gt;'" disable-output-escaping="no"/>
                <xsl:apply-templates mode="m_mark-up"/>
                <![CDATA[</]]><xsl:value-of select="name()"/><![CDATA[>]]>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="tei:*/@*" mode="m_mark-up">
        <xsl:text> </xsl:text>
        <xsl:value-of select="name()"/>
        <xsl:text>="</xsl:text><xsl:value-of select="."/><xsl:text>"</xsl:text>
    </xsl:template>
    <xsl:function name="oape:string-clean-urls">
        <xsl:param name="p_input" as="xs:string"/>
        <xsl:choose>
            <!-- URL components -->
            <xsl:when test="matches($p_input, '&amp;locale=\w+')">
                <xsl:value-of select="oape:string-clean-urls(replace($p_input, '&amp;locale=\w+', ''))"/>
            </xsl:when>
            <!-- specific sites -->
            <xsl:when test="matches($p_input, 'https://babel.hathitrust.org/shcgi/pt?id=')">
                <xsl:value-of select="replace($p_input, '^https*://babel.hathitrust.org/shcgi/pt?id=(.+)$', 'https://hdl.handle.net/2027/$1')"/>
            </xsl:when>
            <xsl:when test="matches($p_input, 'delcampe.net', 'i')">
                <xsl:value-of select="concat('https://www.delcampe.net/en_GB/collectables/item/', parent::tss:characteristics/tss:characteristic[@name = 'call-num'], '.html')"/>
            </xsl:when>
            <!-- rawgit error -->
            <xsl:when test="matches($p_input, 'rawgit.com')">
                <xsl:message>
                    <xsl:text>Error: link to rawgit</xsl:text>
                </xsl:message>
                <xsl:value-of select="$p_input"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$p_input"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
</xsl:stylesheet>