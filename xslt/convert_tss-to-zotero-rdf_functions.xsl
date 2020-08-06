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
  xmlns:tss="http://www.thirdstreetsoftware.com/SenteXML-1.0" xmlns:tei="http://www.tei-c.org/ns/1.0" 
  xmlns:html="http://www.w3.org/1999/xhtml"
  xmlns:prism="http://prismstandard.org/namespaces/1.2/basic/"
  xmlns:link="http://purl.org/rss/1.0/modules/link/"
  xmlns:oape="https://openarabicpe.github.io/ns"
    version="3.0">
    
    <xsl:output method="xml" indent="yes" omit-xml-declaration="no" encoding="UTF-8"/>
    
        <!-- date conversion functions -->
<!--    <xsl:include href="https://tillgrallert.github.io/xslt-calendar-conversion/functions/date-functions.xsl"/>-->
     <xsl:include href="../../../xslt-calendar-conversion/functions/date-functions.xsl"/> 
    <xsl:include href="convert_tss_functions.xsl"/>
    <xsl:variable name="v_new-line" select="'&#x0A;'"/>
    <xsl:variable name="v_separator-key-value" select="': '"/>
    <xsl:variable name="v_cite-key-whitespace-replacement" select="'+'"/>
    
    <!-- to do
        - due to the dependence of fields on the item type in Zotero, everything should also be replicated to the extra field.
        - a lot of information should also be mapped to tags, to make use of the tag cloud (and set of the dearly missing browsing feature)
        - map strcuture of abstract to HTML for abstract notes
        - create short titles based on the title
        - due to Sente's file naming restrictions, I had to use the volume field for issue numbers and vice versa. this is fixed BEFORE converting TSS XML to Zotero RDF.
        - a lot of periodical references have a purely numerical title, which needs to be removed in POSTPROCESSING the TSS XML
    -->
    
     <!-- fields not yet covered 
        + Date read
        + DOI is currently only mapped to the extra field
    -->
    
    <!-- undecided mappings:
        + Archival File -> manuscript
        + Archival Journal Entry
        + Archival Letter -> letter
            - issue: used for numbers of letters and series, i.e. "Slave Trade 1"
            - publicationCountry: can be mapped to "publisher-place" in CSL JSON and will then be picked up by most CSL styles. BUT field not available in Zotero.
                - map to: "place: " in extra field
        + Archival Material -> manuscript
        + Archival Periodical -> newspaper article
        + Bill: since all of the legal texts I am dealing with were published either as part of a book or a periodical, this should be reflected by the itemType in Zotero
            + Book Section
            + Newspaper Article
            + Magazine Article
        + Photo
    -->
    
    <!-- Problems upon import into Zotero: 
        - Software: DVDs are translated into Software, which removes authors if they are not 'Contributors' or 'Programmers'
        - Presentation: only one in my database, skip
            + removes authors if they are not 'Contributors' or 'Presenters'
    -->
    
    <xsl:function name="oape:bibliography-tss-to-zotero-rdf">
        <xsl:param name="tss_reference"/>
<!--        <xsl:param name="p_individual-notes"/>-->
        <xsl:param name="p_include-attachments"/>
        <xsl:param name="p_include-notes"/>
        <!-- values are: individual, single, both -->
        <xsl:param name="p_note-type"/>
        <!-- check reference type, since the first child after the root depends on it -->
        <xsl:variable name="v_reference-type">
            <xsl:variable name="v_temp" select="lower-case($tss_reference/tss:publicationType/@name)"/>
            <xsl:choose>
                <xsl:when test="$v_reference-types/descendant::tei:form[@n = 'tss'][lower-case(.) = $v_temp]">
                    <xsl:copy-of select="$v_reference-types/descendant::tei:form[@n = 'tss'][lower-case(.) = $v_temp]/parent::tei:nym"/>
                </xsl:when>
                <!-- fallback: -->
                <xsl:otherwise>
                    <xsl:message terminate="yes">
                        <xsl:text>reference type "</xsl:text><xsl:value-of select="$v_temp"/><xsl:text>" not found</xsl:text>
                    </xsl:message>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="v_reference-type-bib">
            <xsl:choose>
                    <xsl:when test="$v_reference-type/tei:nym/tei:form[@n = 'bib']!=''">
                        <xsl:value-of select="$v_reference-type/tei:nym/tei:form[@n = 'bib']"/>
                    </xsl:when>
                    <!-- fallback: must be a valid item type for import into Zotero -->
                    <xsl:otherwise>
                        <xsl:text>Book</xsl:text>
                    </xsl:otherwise>
                </xsl:choose>
        </xsl:variable>
        <xsl:variable name="v_reference-type-zotero">
            <xsl:choose>
                    <xsl:when test="$v_reference-type/tei:nym/tei:form[@n = 'zotero']!=''">
                        <xsl:value-of select="$v_reference-type/tei:nym/tei:form[@n = 'zotero']"/>
                    </xsl:when>
                    <!-- fallback: must be a valid item type for import into Zotero -->
                    <xsl:otherwise>
                        <xsl:text>book</xsl:text>
                    </xsl:otherwise>
                </xsl:choose>
        </xsl:variable>
        <xsl:variable name="v_reference-type-sente" select="$v_reference-type/tei:nym/tei:form[@n = 'tss']"/>
        <xsl:variable name="v_reference-is-section" select="if($tss_reference/descendant::tss:characteristic[@name = 'articleTitle'] != '') then(true()) else(false())"/>
        <xsl:variable name="v_reference-is-part-of-series" select="if($tss_reference/descendant::tss:characteristic[@name = 'Series'] != '') then(true()) else(false())"/>
        <xsl:variable name="v_series">
            <dcterms:isPartOf>
                    <bib:Series>
                        <xsl:apply-templates select="$tss_reference/descendant::tss:characteristic[@name = 'Series']" mode="m_tss-to-zotero-rdf"/>
                        <xsl:apply-templates select="$tss_reference/descendant::tss:characteristic[@name = 'Series number']" mode="m_tss-to-zotero-rdf"/>
                    </bib:Series>
                </dcterms:isPartOf>
        </xsl:variable>
        <!-- output -->
        <xsl:element name="bib:{$v_reference-type-bib}">
            <!-- add an ID -->
            <xsl:attribute name="rdf:about" select="concat('#',$tss_reference/descendant::tss:characteristic[@name = 'UUID'])"/>
            <!-- itemType -->
            <z:itemType>
                <xsl:value-of select="$v_reference-type-zotero"/>
            </z:itemType>
            <!-- titles -->
            <xsl:choose>
                <!-- check if the reference is part of a larger work (i.e. a chapter, article) -->
                <xsl:when test="$v_reference-is-section = true()">
                    <dcterms:isPartOf>
                        <xsl:choose>
                            <!-- book chapters -->
                            <xsl:when test="$v_reference-type-bib = 'BookSection'">
                                <bib:Book>
                                    <!-- check if reference is part of a series -->
                                    <xsl:if test="$v_reference-is-part-of-series = true()">
                                        <xsl:copy-of select="$v_series"/>
                                    </xsl:if>
                                    <xsl:apply-templates select="$tss_reference/descendant::tss:characteristic[@name = 'publicationTitle']" mode="m_tss-to-zotero-rdf"/>
                                </bib:Book>
                            </xsl:when>
                            <!-- periodical articles -->
                            <xsl:when test="$v_reference-type-bib = 'Article'">
                                <bib:Periodical>
                                    <xsl:apply-templates select="$tss_reference/descendant::tss:characteristic[@name = 'volume']" mode="m_tss-to-zotero-rdf"/>
                <xsl:apply-templates select="$tss_reference/descendant::tss:characteristic[@name = 'issue']" mode="m_tss-to-zotero-rdf"/>
                                    <xsl:apply-templates select="$tss_reference/descendant::tss:characteristic[@name = 'publicationTitle']" mode="m_tss-to-zotero-rdf"/>
                                </bib:Periodical>
                            </xsl:when>
                            <!-- maps: it seems that the articleTitle should be mapped to Series -->
                            <xsl:when test="$v_reference-type-zotero = 'map'"/>
                            <!-- fallback: book -->
                            <xsl:otherwise>
                                <bib:Book>
                                    <!-- check if reference is part of a series -->
                                    <xsl:if test="$v_reference-is-part-of-series = true()">
                                        <xsl:copy-of select="$v_series"/>
                                    </xsl:if>
                                    <xsl:apply-templates select="$tss_reference/descendant::tss:characteristic[@name = 'publicationTitle']" mode="m_tss-to-zotero-rdf"/>
                                </bib:Book>
                            </xsl:otherwise>
                        </xsl:choose>
                    </dcterms:isPartOf>
                    <!-- check if an item is part of a series -->
                    <xsl:apply-templates select="$tss_reference/descendant::tss:characteristic[@name = 'articleTitle']" mode="m_tss-to-zotero-rdf"/>
                </xsl:when>
                <xsl:otherwise>
                    <!-- check if reference is part of a series -->
                    <xsl:if test="$v_reference-is-part-of-series = true()">
                        <xsl:copy-of select="$v_series"/>
                    </xsl:if>
                    <xsl:apply-templates select="$tss_reference/descendant::tss:characteristic[@name = 'publicationTitle']" mode="m_tss-to-zotero-rdf"/>
                </xsl:otherwise>
            </xsl:choose>
            <!-- short titles -->
            <xsl:choose>
                <xsl:when test="$tss_reference/descendant::tss:characteristic[@name = 'Short Titel']">
                    <xsl:apply-templates select="$tss_reference/descendant::tss:characteristic[@name = 'Short Titel']" mode="m_tss-to-zotero-rdf"/>
                </xsl:when>
                <xsl:when test="$tss_reference/descendant::tss:characteristic[@name = 'Shortened title']">
                    <xsl:apply-templates select="$tss_reference/descendant::tss:characteristic[@name = 'Shortened title']" mode="m_tss-to-zotero-rdf"/>
                </xsl:when>
                <!-- fallback: create a short title -->
                <xsl:otherwise>
                    <xsl:variable name="v_title-temp" select="if($v_reference-is-section = true()) then($tss_reference/descendant::tss:characteristic[@name = 'articleTitle']) else($tss_reference/descendant::tss:characteristic[@name = 'publicationTitle'])"/>
                    <xsl:analyze-string select="$v_title-temp" regex="^(.+?)([:|\.|\?])(.+)$">
                        <xsl:matching-substring>
                            <z:shortTitle><xsl:value-of select="regex-group(1)"/></z:shortTitle>
                        </xsl:matching-substring>
                        <xsl:non-matching-substring>
                            <z:shortTitle>
                            <xsl:for-each select="tokenize($v_title-temp,'\s')">
                                <xsl:if test="position() &lt;= 5">
                                    <xsl:value-of select="."/>
                                    <xsl:if test="position() &lt;= 4">
                                        <xsl:text> </xsl:text>
                                    </xsl:if>
                                </xsl:if>
                            </xsl:for-each>
                            </z:shortTitle>
                        </xsl:non-matching-substring>
                    </xsl:analyze-string>
                </xsl:otherwise>
            </xsl:choose>
            <!-- contributors: authors, editors etc. -->
            <xsl:apply-templates select="$tss_reference/descendant::tss:authors" mode="m_tss-to-zotero-rdf"/>
            <xsl:apply-templates select="$tss_reference/descendant::tss:characteristic[@name = 'Recipient']" mode="m_tss-to-zotero-rdf"/>
            <!-- publisher: name, location -->
        <xsl:copy-of select="oape:bibliography-tss-to-zotero-rdf-publisher($tss_reference)"/>
            <!-- links to notes -->
            <xsl:if test="$p_include-notes = true()">
                <xsl:choose>
                    <xsl:when test="$p_note-type = 'individual'">
                        <xsl:apply-templates select="$tss_reference/descendant::tss:note" mode="m_links"/>
                    </xsl:when>
                    <xsl:when test="$p_note-type = 'single'">
                        <xsl:apply-templates select="$tss_reference/descendant::tss:notes" mode="m_links"/>
                    </xsl:when>
                    <xsl:when test="$p_note-type = 'both'">
                        <xsl:apply-templates select="$tss_reference/descendant::tss:notes" mode="m_links"/>
                        <xsl:apply-templates select="$tss_reference/descendant::tss:note" mode="m_links"/>
                    </xsl:when>
                </xsl:choose>
            </xsl:if>
            <!-- links to attachment references -->
            <xsl:if test="$p_include-attachments = true()">
                <xsl:apply-templates select="$tss_reference/descendant::tss:attachmentReference" mode="m_links"/>
            </xsl:if>
            <xsl:if test="$tss_reference/descendant::tss:characteristic[@name = 'abstractText'] !=''">
                <dcterms:isReferencedBy rdf:resource="{concat('#',$tss_reference/descendant::tss:characteristic[@name = 'UUID'],'-abstract')}"/>
            </xsl:if>
        <!-- tags, keywords etc. -->
        <xsl:apply-templates select="$tss_reference/descendant::tss:keyword" mode="m_tss-to-zotero-rdf"/>
        <!-- URLs -->
        <xsl:apply-templates select="$tss_reference/descendant::tss:characteristic[@name = 'URL']" mode="m_tss-to-zotero-rdf"/>
            <!-- Identitifiers -->
            <!-- edition -->
            <xsl:apply-templates select="$tss_reference/descendant::tss:characteristic[@name = 'Edition']" mode="m_tss-to-zotero-rdf"/>
            <!-- volume, issue: depends on work not being a chapter or article -->
            <xsl:if test="$v_reference-is-section = false()">
                <xsl:apply-templates select="$tss_reference/descendant::tss:characteristic[@name = 'volume']" mode="m_tss-to-zotero-rdf"/>
                <xsl:apply-templates select="$tss_reference/descendant::tss:characteristic[@name = 'issue']" mode="m_tss-to-zotero-rdf"/>
            </xsl:if>
                <xsl:apply-templates select="$tss_reference/descendant::tss:characteristic[@name = 'pages']" mode="m_tss-to-zotero-rdf"/>
            <!-- dates -->
            <xsl:apply-templates select="$tss_reference/descendant::tss:date[@type = 'Publication']" mode="m_tss-to-zotero-rdf"/>
            <!-- Archive, repository -->
            <xsl:apply-templates select="$tss_reference/descendant::tss:characteristic[@name = 'Repository']" mode="m_tss-to-zotero-rdf"/>
            <!-- Library catalogue, Standort -->
            <xsl:apply-templates select="$tss_reference/descendant::tss:characteristic[@name = 'Standort']" mode="m_tss-to-zotero-rdf"/>
            <!-- call number -->
            <xsl:apply-templates select="$tss_reference/descendant::tss:characteristic[@name = 'Signatur']" mode="m_tss-to-zotero-rdf"/>
            <xsl:apply-templates select="$tss_reference/descendant::tss:characteristic[@name = 'call-num']" mode="m_tss-to-zotero-rdf"/>
            <!-- retrieval date -->
            <xsl:apply-templates select="$tss_reference/descendant::tss:date[@type = 'Retrieval']" mode="m_tss-to-zotero-rdf"/>
            <!-- extra field: map all sorts of custom fields -->
            <dc:description>
                <xsl:apply-templates select="$tss_reference/descendant::tss:characteristic[@name = 'Citation identifier']" mode="m_extra-field"/>
                <xsl:apply-templates select="$tss_reference/descendant::tss:characteristic[@name = 'Date Rumi']" mode="m_extra-field"/>
                <xsl:apply-templates select="$tss_reference/descendant::tss:characteristic[@name = 'Date Hijri']" mode="m_extra-field"/>
                <xsl:apply-templates select="$tss_reference/descendant::tss:characteristic[@name = 'DOI']" mode="m_extra-field"/>
                <xsl:apply-templates select="$tss_reference/descendant::tss:characteristic[@name = 'ISBN']" mode="m_extra-field"/>
                <xsl:apply-templates select="$tss_reference/descendant::tss:characteristic[@name = 'OCLCID']" mode="m_extra-field"/>
                
                <!-- original date, title -->
                <xsl:apply-templates select="$tss_reference/descendant::tss:characteristic[@name = 'Original publication year']" mode="m_extra-field"/>
                <xsl:apply-templates select="$tss_reference/descendant::tss:characteristic[@name = 'Orig.Title']" mode="m_extra-field"/>
                <xsl:apply-templates select="$tss_reference/descendant::tss:characteristic[@name = 'Translated title']" mode="m_extra-field"/>
                <xsl:apply-templates select="$tss_reference/descendant::tss:characteristic[@name = 'issue']" mode="m_extra-field"/>
                <!-- make this dependent on the reference type: letter etc. -->
                <xsl:apply-templates select="$tss_reference/descendant::tss:characteristic[@name = 'publicationCountry']" mode="m_extra-field"/>
                <xsl:apply-templates select="$tss_reference/descendant::tss:characteristic[@name = 'UUID']" mode="m_extra-field"/>
                <xsl:apply-templates select="$tss_reference/descendant::tss:characteristic[@name = 'volume']" mode="m_extra-field"/>
            </dc:description>
            <!-- language -->
             <xsl:apply-templates select="$tss_reference/descendant::tss:characteristic[@name = 'language']" mode="m_tss-to-zotero-rdf"/>
            <!-- abstract -->
            <xsl:apply-templates select="$tss_reference/descendant::tss:characteristic[@name = 'abstractText']" mode="m_tss-to-zotero-rdf"/>
            <!-- ISBN, ISSN etc. -->
            <xsl:apply-templates select="$tss_reference/descendant::tss:characteristic[@name = 'ISBN']" mode="m_tss-to-zotero-rdf"/>
            <!-- number of volumes -->
            <xsl:apply-templates select="$tss_reference/descendant::tss:characteristic[@name = 'Number of volumes']" mode="m_tss-to-zotero-rdf"/>
            <!-- add <z:type> for archival material -->
            <xsl:if test="$v_reference-type-sente = 'Archival File'">
                <xsl:element name="z:type">
                    <xsl:text>file</xsl:text>
                </xsl:element>
            </xsl:if>
        </xsl:element>
        <!-- notes -->
        <xsl:if test="$p_include-notes = true()">
            <xsl:choose>
                <xsl:when test="$p_note-type = 'individual'">
                    <xsl:apply-templates select="$tss_reference/descendant::tss:note" mode="m_tss-to-zotero-rdf">
                        <xsl:sort select="tss:pages" order="ascending"/>
                    </xsl:apply-templates>
                </xsl:when>
                <xsl:when test="$p_note-type = 'single'">
                    <xsl:apply-templates select="$tss_reference/descendant::tss:notes" mode="m_tss-to-zotero-rdf">
                        <xsl:sort select="tss:pages" order="ascending"/>
                    </xsl:apply-templates>
                </xsl:when>
                <xsl:when test="$p_note-type = 'both'">
                    <xsl:apply-templates select="$tss_reference/descendant::tss:notes" mode="m_tss-to-zotero-rdf">
                        <xsl:sort select="tss:pages" order="ascending"/>
                    </xsl:apply-templates>
                    <xsl:apply-templates select="$tss_reference/descendant::tss:note" mode="m_tss-to-zotero-rdf">
                        <xsl:sort select="tss:pages" order="ascending"/>
                    </xsl:apply-templates>
                </xsl:when>
            </xsl:choose>
        </xsl:if>
        <xsl:apply-templates select="$tss_reference/descendant::tss:characteristic[@name = 'abstractText']" mode="m_construct-note"/>
        <!-- attachments -->
        <xsl:if test="$p_include-attachments = true()">
            <xsl:apply-templates select="$tss_reference/descendant::tss:attachmentReference
            " mode="m_tss-to-zotero-rdf"/>
        </xsl:if>
    </xsl:function>
    
    <xsl:function name="oape:bibliography-tss-to-zotero-rdf-publisher">
        <!-- expects tss:reference -->
        <xsl:param name="tss_reference"/>
    <dc:publisher>
            <foaf:Organization>
                <vcard:adr>
                    <vcard:Address>
                       <vcard:locality><xsl:value-of select="$tss_reference/descendant::tss:characteristic[@name = 'publicationCountry']"/></vcard:locality>
                    </vcard:Address>
                </vcard:adr>
                <foaf:name><xsl:value-of select="$tss_reference/descendant::tss:characteristic[@name = ('publisher', 'affiliation')]"/></foaf:name>
            </foaf:Organization>
        </dc:publisher>
    </xsl:function>
    
    <!-- extra field -->
    <xsl:template match="tss:characteristic[@name = 'UUID']" mode="m_extra-field">
        <xsl:value-of select="concat('uuid', $v_separator-key-value,.,$v_new-line)"/>
    </xsl:template>
    <xsl:template match="tss:characteristic[@name = 'DOI']" mode="m_extra-field">
        <xsl:if test=".!=''">
            <xsl:value-of select="concat('doi', $v_separator-key-value,.,$v_new-line)"/>
        </xsl:if>
    </xsl:template>
    <xsl:template match="tss:characteristic[@name = 'ISBN']" mode="m_extra-field">
        <xsl:if test=".!=''">
            <xsl:value-of select="concat('isbn', $v_separator-key-value,.,$v_new-line)"/>
        </xsl:if>
    </xsl:template>
    <xsl:template match="tss:characteristic[@name = 'ISBN']" mode="m_tss-to-zotero-rdf">
        <dc:identifier><xsl:value-of select="concat('ISBN ', .)"/></dc:identifier>
    </xsl:template>
    <xsl:template match="tss:characteristic[@name = 'OCLCID']" mode="m_extra-field">
        <xsl:if test=".!=''">
            <xsl:value-of select="concat('oclc', $v_separator-key-value,.,$v_new-line)"/>
        </xsl:if>
    </xsl:template>
    <!-- if used with Better BibTeX, one can set the citation key in the extra field -->
    <xsl:template match="tss:characteristic[@name = 'Citation identifier']" mode="m_extra-field">
        <xsl:if test=".!=''">
            <xsl:value-of select="concat('Citation Key', $v_separator-key-value, replace(.,'\s+', $v_cite-key-whitespace-replacement),$v_new-line)"/>
        </xsl:if>
    </xsl:template>
    <xsl:template match="tss:characteristic[@name = 'Date Rumi']" mode="m_extra-field">
        <!-- try to establish the calendar -->
        <xsl:variable name="v_calendar-guessed" select="oape:date-establish-calendar(.)"/>
        <xsl:variable name="v_calendar">
            <xsl:choose>
                <xsl:when test="$v_calendar-guessed != ''">
                    <xsl:value-of select="$v_calendar-guessed"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>#cal_julian</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="v_date-normalised" select="oape:date-normalise-input(.,'ar-Latn-x-sente', $v_calendar)"/>
        <!--<xsl:message>
            <xsl:value-of select="$v_date-normalised"/>
        </xsl:message>-->
        <!-- content -->
        <xsl:text>date_</xsl:text>
        <xsl:choose>
            <xsl:when test="$v_calendar = '#cal_julian'">
                <xsl:text>rumi</xsl:text>
            </xsl:when>
            <xsl:when test="$v_calendar = '#cal_ottomanfiscal'">
                <xsl:text>mali</xsl:text>
            </xsl:when>
        </xsl:choose>
        <xsl:value-of select="concat($v_separator-key-value, $v_date-normalised, $v_new-line)"/>
    </xsl:template>
    <xsl:template match="tss:characteristic[@name = 'Date Hijri']" mode="m_extra-field">
        <xsl:variable name="v_date-normalised" select="oape:date-normalise-input(.,'ar-Latn-x-sente','#cal_islamic')"/>
        <xsl:text>date_hijri</xsl:text>
        <xsl:value-of select="concat($v_separator-key-value, $v_date-normalised, $v_new-line)"/>
    </xsl:template>
    <xsl:template match="tss:characteristic[@name = 'issue']" mode="m_extra-field">
        <xsl:if test=".!=''">
            <!--<xsl:choose>
                 <xsl:when test="oape:bibliography-tss-switch-volume-and-issue(ancestor::tss:reference) = false()">
                     <xsl:text>issue</xsl:text>
                 </xsl:when>
                 <xsl:otherwise>
                     <xsl:text>volume</xsl:text>
                 </xsl:otherwise>
             </xsl:choose>-->
            <xsl:value-of select="concat('issue', $v_separator-key-value,.,$v_new-line)"/>
        </xsl:if>
    </xsl:template>
     <xsl:template match="tss:characteristic[@name = 'volume']" mode="m_extra-field">
         <xsl:if test=".!=''">
             <!--<xsl:choose>
                 <xsl:when test="oape:bibliography-tss-switch-volume-and-issue(ancestor::tss:reference) = true()">
                     <xsl:text>issue</xsl:text>
                 </xsl:when>
                 <xsl:otherwise>
                     <xsl:text>volume</xsl:text>
                 </xsl:otherwise>
             </xsl:choose>-->
             <xsl:value-of select="concat('volume', $v_separator-key-value,.,$v_new-line)"/>
         </xsl:if>
    </xsl:template>
    <xsl:template match="tss:characteristic[@name = 'publicationCountry']" mode="m_extra-field">
        <xsl:if test=".!=''">
            <xsl:value-of select="concat('place', $v_separator-key-value,.,$v_new-line)"/>
        </xsl:if>
    </xsl:template>
    <xsl:template match="tss:characteristic[@name = 'Original publication year']" mode="m_extra-field">
        <xsl:if test=".!=''">
            <xsl:value-of select="concat('original-date', $v_separator-key-value,.,$v_new-line)"/>
        </xsl:if>
    </xsl:template>
    <xsl:template match="tss:characteristic[@name = 'Original publication year']" mode="m_extra-field">
        <xsl:if test=".!=''">
            <xsl:value-of select="concat('original-date', $v_separator-key-value,.,$v_new-line)"/>
        </xsl:if>
    </xsl:template>
    <xsl:template match="tss:characteristic[@name = 'Orig.Title']" mode="m_extra-field">
        <xsl:if test=".!=''">
            <xsl:value-of select="concat('original-title', $v_separator-key-value,.,$v_new-line)"/>
        </xsl:if>
    </xsl:template>
    <xsl:template match="tss:characteristic[@name = 'Translated title']" mode="m_extra-field">
        <xsl:if test=".!=''">
            <xsl:value-of select="concat('translated-title', $v_separator-key-value,.,$v_new-line)"/>
        </xsl:if>
    </xsl:template>
    
    <!-- contributors -->
    <xsl:template match="tss:authors" mode="m_tss-to-zotero-rdf">
        <!-- the authors should be further differentiated -->
        <xsl:if test="tss:author/@role = ('Author', 'Compiler', 'Photographer')">
            <xsl:choose>
                <xsl:when test="ancestor::tss:reference/tss:publicationType/@name = 'Presentation'">
                    <z:presenters> 
                        <rdf:Seq> 
                             <xsl:apply-templates select="tss:author[@role = ('Author')]" mode="m_tss-to-zotero-rdf"/>
                        </rdf:Seq> 
                    </z:presenters>
                </xsl:when>
                <xsl:otherwise>
            <bib:authors>
                    <rdf:Seq>
                        <xsl:apply-templates select="tss:author[@role = ('Author', 'Compiler','Photographer')]" mode="m_tss-to-zotero-rdf"/>
                    </rdf:Seq>
                </bib:authors>
                </xsl:otherwise>
            </xsl:choose>
            </xsl:if>
            <xsl:if test="tss:author/@role = ('Editor', 'Director')">
                <bib:editors>
                    <rdf:Seq>
                        <xsl:apply-templates select="tss:author[@role = ('Editor', 'Director')]" mode="m_tss-to-zotero-rdf"/>
                    </rdf:Seq>
                </bib:editors>
            </xsl:if>
            <xsl:if test="tss:author/@role = 'Translator'">
                <z:translators>
                    <rdf:Seq>
                            <xsl:apply-templates select="tss:author[@role = 'Translator']" mode="m_tss-to-zotero-rdf"/>
                    </rdf:Seq>
                </z:translators>
            </xsl:if>
        <xsl:if test="tss:author/@role = 'Contributor'">
                <bib:contributors>
                    <rdf:Seq>
                            <xsl:apply-templates select="tss:author[@role = 'Contributor']" mode="m_tss-to-zotero-rdf"/>
                    </rdf:Seq>
                </bib:contributors>
            </xsl:if>
    </xsl:template>
    <xsl:template match="tss:characteristic[@name = 'Recipient']" mode="m_tss-to-zotero-rdf">
        <z:recipients>
                    <rdf:Seq>
                        <rdf:li>
                            <foaf:Person>
                                <foaf:surname><xsl:apply-templates/></foaf:surname>
                            </foaf:Person>
                        </rdf:li>
                    </rdf:Seq>
                </z:recipients>
    </xsl:template>
    
    <xsl:template match="tss:author" mode="m_tss-to-zotero-rdf">
        <rdf:li>
            <foaf:Person>
                <xsl:apply-templates select="tss:surname" mode="m_tss-to-zotero-rdf"/>
                <xsl:apply-templates select="tss:forenames" mode="m_tss-to-zotero-rdf"/>
            </foaf:Person>
        </rdf:li>
    </xsl:template>
    <xsl:template match="tss:surname" mode="m_tss-to-zotero-rdf">
        <foaf:surname><xsl:apply-templates/></foaf:surname>
    </xsl:template>
    <xsl:template match="tss:forenames" mode="m_tss-to-zotero-rdf">
        <foaf:givenName><xsl:apply-templates/></foaf:givenName>
    </xsl:template>
    
    <!-- keywords, tags, status -->
    <xsl:template match="tss:keyword[matches(@assigner,'Sente User')]" mode="m_tss-to-zotero-rdf">
        <dc:subject>
            <xsl:apply-templates/>
        </dc:subject>
        <!-- add all members of the QuickTag hierarchy -->
    </xsl:template>
    <xsl:template match="tss:characteristic[@name = 'status']" mode="m_tss-to-zotero-rdf">
        <dc:subject>
            <xsl:text>status_</xsl:text><xsl:value-of select="replace(.,' ','-')"/>
        </dc:subject>
    </xsl:template>
    
    <!-- titles -->
    <xsl:template match="tss:characteristic[@name = ('publicationTitle', 'articleTitle', 'Series')]" mode="m_tss-to-zotero-rdf">
        <xsl:if test=".!=''">
            <dc:title><xsl:apply-templates/></dc:title>
        </xsl:if>
    </xsl:template>
    <xsl:template match="tss:characteristic[@name = ('Short Titel', 'Shortened title')]" mode="m_tss-to-zotero-rdf">
        <xsl:if test=".!=''">
            <z:shortTitle><xsl:apply-templates/></z:shortTitle>
        </xsl:if>
    </xsl:template>
    <xsl:template match="tss:characteristic[@name = ('Series number')]" mode="m_tss-to-zotero-rdf">
        <xsl:if test=".!=''">
            <dc:identifier><xsl:apply-templates/></dc:identifier>
        </xsl:if>
    </xsl:template>
       <!-- transform dates -->
    <xsl:template match="tss:date" mode="m_tss-to-zotero-rdf">
        <xsl:variable name="v_year" select="if(@year!='') then(format-number(@year,'0000')) else()"/>
        <xsl:variable name="v_month" select="if(@month!='') then(format-number(@month,'00')) else('xx')"/>
        <xsl:variable name="v_day" select="if(@day!='') then(format-number(@day,'00')) else('xx')"/>
        <xsl:variable name="v_date-formatted">
            <xsl:value-of select="if(@year!='') then(format-number(@year,'0000')) else()"/>
            <xsl:if test="@month!=''">
                <xsl:text>-</xsl:text>
                <xsl:value-of select="format-number(@month,'00')"/>
            </xsl:if>
            <xsl:if test="@day!=''">
                <xsl:text>-</xsl:text>
                <xsl:value-of select="format-number(@day,'00')"/>
            </xsl:if>
        </xsl:variable>
        <xsl:choose>
            <xsl:when test="@type = 'Retrieval'">
                <dcterms:dateSubmitted><xsl:value-of select="$v_date-formatted"/></dcterms:dateSubmitted>
            </xsl:when>
            <xsl:otherwise>
                <dc:date><xsl:value-of select="$v_date-formatted"/></dc:date>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="tss:characteristic[@name = 'URL']" mode="m_tss-to-zotero-rdf">
        <dc:identifier>
            <dcterms:URI>
                <rdf:value><xsl:value-of select="."/></rdf:value>
            </dcterms:URI>
        </dc:identifier>
    </xsl:template>
    <xsl:template match="tss:characteristic[@name = 'Edition']" mode="m_tss-to-zotero-rdf">
        <prism:edition><xsl:value-of select="."/></prism:edition>
    </xsl:template>
    <xsl:template match="tss:characteristic[@name = 'Number of volumes']" mode="m_tss-to-zotero-rdf">
        <z:numberOfVolumes><xsl:value-of select="."/></z:numberOfVolumes>
    </xsl:template>
    <xsl:template match="tss:characteristic[@name = 'volume']" mode="m_tss-to-zotero-rdf">
        <xsl:if test=".!=''">
            <!--<xsl:choose>
                 <xsl:when test="oape:bibliography-tss-switch-volume-and-issue(ancestor::tss:reference) = true()">
                    <prism:number><xsl:value-of select="."/></prism:number>
                 </xsl:when>
                 <xsl:otherwise>
                     <prism:volume><xsl:value-of select="."/></prism:volume>
                 </xsl:otherwise>
             </xsl:choose>-->
            <prism:volume><xsl:value-of select="."/></prism:volume>
        </xsl:if>
    </xsl:template>
    <xsl:template match="tss:characteristic[@name = 'issue']" mode="m_tss-to-zotero-rdf">
        <xsl:if test=".!=''">
            <!--<xsl:choose>
                 <xsl:when test="oape:bibliography-tss-switch-volume-and-issue(ancestor::tss:reference) = false()">
                    <prism:number><xsl:value-of select="."/></prism:number>
                 </xsl:when>
                 <xsl:otherwise>
                     <prism:volume><xsl:value-of select="."/></prism:volume>
                 </xsl:otherwise>
             </xsl:choose>-->
            <prism:number><xsl:value-of select="."/></prism:number>
        </xsl:if>
    </xsl:template>
    <xsl:template match="tss:characteristic[@name = 'pages']" mode="m_tss-to-zotero-rdf">
        <xsl:if test=".!=''">
            <bib:pages><xsl:value-of select="."/></bib:pages>
        </xsl:if>
    </xsl:template>
    <xsl:template match="tss:characteristic[@name = 'language']" mode="m_tss-to-zotero-rdf">
        <xsl:if test=".!=''">
            <z:language><xsl:value-of select="."/></z:language>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="tss:characteristic[@name = 'abstractText']" mode="m_tss-to-zotero-rdf">
        <xsl:if test=".!=''">
            <dcterms:abstract>
                <xsl:apply-templates/>
<!--                <xsl:apply-templates mode="m_mark-up"/>-->
            </dcterms:abstract>
        </xsl:if>
    </xsl:template>
    
    <!-- information for locating physical artefact -->
    <xsl:template match="tss:characteristic[@name = 'Repository']" mode="m_tss-to-zotero-rdf">
        <xsl:if test=".!=''">
            <z:archive><xsl:value-of select="."/></z:archive>
        </xsl:if>
    </xsl:template>
    <xsl:template match="tss:characteristic[@name = 'Standort']" mode="m_tss-to-zotero-rdf">
        <xsl:if test=".!=''">
            <z:libraryCatalog><xsl:value-of select="."/></z:libraryCatalog>
        </xsl:if>
    </xsl:template>
    
    <!-- call-numbers -->
    <xsl:template match="tss:characteristic[@name = ('Signatur', 'call-num')]" mode="m_tss-to-zotero-rdf">
        <xsl:if test=".!=''">
        <xsl:choose>
            <!-- for archival reference the call-number should be mapped to location in archive -->
            <xsl:when test="ancestor::tss:reference/tss:publicationType/@name = ('Archival File', 'Archival Material', 'Archival Letter')">
                <dc:coverage>
                    <xsl:apply-templates/>
                </dc:coverage>
            </xsl:when>
            <xsl:otherwise>
                <dc:subject>
                    <dcterms:LCC>
                        <rdf:value>
                            <xsl:apply-templates/>
                        </rdf:value>
                    </dcterms:LCC>
                </dc:subject>
            </xsl:otherwise>
        </xsl:choose>
        </xsl:if>
    </xsl:template>
    
    <!-- links to notes and attachment references -->
    <xsl:template match="tss:note" mode="m_links">
        <dcterms:isReferencedBy rdf:resource="{concat('#',@xml:id)}"/>
    </xsl:template>
    <xsl:template match="tss:notes" mode="m_links">
        <dcterms:isReferencedBy rdf:resource="{concat('#',parent::tss:reference/tss:characteristics/tss:characteristic[@name = 'UUID'],'-notes')}"/>
    </xsl:template>
    <xsl:template match="tss:attachmentReference" mode="m_links">
        <link:link rdf:resource="{concat('#',@xml:id)}"/>
    </xsl:template>
    
    <!-- notes -->
    <xsl:template match="tss:note" mode="m_tss-to-zotero-rdf">
        <bib:Memo>
            <!-- each note needs an ID -->
            <xsl:attribute name="rdf:about" select="concat('#',@xml:id)"/>
            <rdf:value>
                <xsl:copy-of select="oape:bibliography-tss-note-to-html(.)"/>
            </rdf:value>
        </bib:Memo>
    </xsl:template>
    <xsl:template match="tss:notes" mode="m_tss-to-zotero-rdf">
        <bib:Memo>
            <!-- each note needs an ID -->
            <xsl:attribute name="rdf:about" select="concat('#',parent::tss:reference/tss:characteristics/tss:characteristic[@name = 'UUID'],'-notes')"/>
            <rdf:value>
                <!-- title: there should be a title added here -->
                <![CDATA[<h1>]]><xsl:text># notes</xsl:text><![CDATA[</h1>]]>
                <!-- notes -->
                <xsl:for-each select="tss:note">
                    <xsl:sort select="tss:pages" order="ascending" data-type="number"/>
                    <xsl:copy-of select="oape:bibliography-tss-note-to-html(.)"/>
                </xsl:for-each>
            </rdf:value>
        </bib:Memo>
    </xsl:template>
    <xsl:template match="tss:characteristic[@name = 'abstractText']" mode="m_construct-note">
        <xsl:if test=".!=''">
            <bib:Memo>
            <!-- each note needs an ID: use UUID -->
                <xsl:attribute name="rdf:about" select="concat('#',parent::tss:characteristics/tss:characteristic[@name = 'UUID'],'-abstract')"/>
                <rdf:value>
                    <![CDATA[<h1>]]><xsl:text># abstract</xsl:text><![CDATA[</h1>]]>
                    <xsl:apply-templates select="." mode="m_mark-up"/>
                </rdf:value>
            </bib:Memo>
        </xsl:if>
    </xsl:template>
    
    <!-- attachments -->
    <xsl:template match="tss:attachmentReference" mode="m_tss-to-zotero-rdf">
        <z:Attachment rdf:about="{concat('#',@xml:id)}">
            <z:itemType>attachment</z:itemType>
            <!-- local URL -->
            <xsl:apply-templates select="tss:URL[@storageMethod = 'Base Directory-Relative, Optionally Alias-Backed']" mode="m_tss-to-zotero-rdf"/>
            <!-- date of attachment: will be overwritten upon import -->
<!--            <dcterms:dateSubmitted>2018-04-03 07:11:40</dcterms:dateSubmitted>-->
            <!-- name -->
            <xsl:apply-templates select="tss:name" mode="m_tss-to-zotero-rdf"/>
            <z:linkMode>
                <xsl:choose>
                    <xsl:when test="tss:URL/@storageMethod = 'Base Directory-Relative, Optionally Alias-Backed'">
                        <xsl:value-of select="2"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="1"/>
                    </xsl:otherwise>
                </xsl:choose>
            </z:linkMode>
            <!-- the type doesn't need to be declared upon import -->
<!--            <xsl:apply-templates select="@type" mode="m_tss-to-zotero-rdf"/>-->
        </z:Attachment>
    </xsl:template>
    
    <xsl:template match="tss:name" mode="m_tss-to-zotero-rdf">
        <dc:title>
            <xsl:apply-templates/>
        </dc:title>
    </xsl:template>
    <xsl:template match="tss:URL" mode="m_tss-to-zotero-rdf">
        <xsl:choose>
            <xsl:when test="@storageMethod = 'Base Directory-Relative, Optionally Alias-Backed'">
                <rdf:resource rdf:resource="{.}"/>
            </xsl:when>
            <xsl:otherwise>
                <dc:identifier>
                    <dcterms:URI>
                        <rdf:value>
                            <xsl:apply-templates/>
                        </rdf:value>
                    </dcterms:URI>
                </dc:identifier>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- the type doesn't need to be declared upon import -->
    <xsl:template match="tss:attachmentReference/@type" mode="m_tss-to-zotero-rdf">
        <!-- type mappings:
            - application/pdf
            - text/html 
        -->
        <link:type></link:type>
    </xsl:template>
    
    <!-- HTML mark-up inside abstracts and notes? -->
    <xsl:template match="html:*" mode="m_tss-to-zotero-rdf"/>
    <xsl:template match="tss:characteristic[@name = 'abstractText']" mode="m_mark-up">
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
    <xsl:template match="html:br" mode="m_mark-up"/>
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
    
</xsl:stylesheet>