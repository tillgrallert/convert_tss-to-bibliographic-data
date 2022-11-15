<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="3.0" xmlns:bib="http://purl.org/net/biblio#" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:dcterms="http://purl.org/dc/terms/" xmlns:foaf="http://xmlns.com/foaf/0.1/"
    xmlns:html="http://www.w3.org/1999/xhtml" xmlns:link="http://purl.org/rss/1.0/modules/link/" xmlns:oape="https://openarabicpe.github.io/ns"
    xmlns:prism="http://prismstandard.org/namespaces/1.2/basic/" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:tss="http://www.thirdstreetsoftware.com/SenteXML-1.0" xmlns:vcard="http://nwalsh.com/rdf/vCard#" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:z="http://www.zotero.org/namespaces/export#">

    <!-- date conversion functions -->
    <!--    <xsl:include href="https://tillgrallert.github.io/xslt-calendar-conversion/functions/date-functions.xsl"/>-->
    <xsl:include href="../../../xslt-calendar-conversion/functions/date-functions.xsl"/>
    <xsl:include href="convert_tss_functions.xsl"/>
    <xsl:variable name="v_new-line" select="'&#x0A;'"/>
    <xsl:variable name="v_separator-key-value" select="': '"/>
    <xsl:variable name="v_cite-key-whitespace-replacement" select="'+'"/>
    <xsl:param name="p_letters-discard-reference-in-title" select="true()"/>

    <!-- to do
        - Preprocess Sente export
        - prevent data duplication through the extra field as this will be picked up by CSL styles
    -->

    <!-- fields not yet covered 
        + DOI is currently only mapped to the extra field
            - which works well upon import into Zotero
    -->

    <!--  mappings:
        + Archival File -> manuscript 
            - plus: type/genre "file"
        + Archival Journal Entry -> manuscript
            - plus: type/genre "journal entry"
        + Archival Letter -> letter
            - issue: used for numbers of letters and series, i.e. "Slave Trade 1"
                - mapped to the extra field as:
                    + Series: Slave Trade
                    + Series Number: 1
            - publicationCountry: can be mapped to "publisher-place" in CSL JSON and will then be picked up by most CSL styles. BUT field not available in Zotero.
                - mapped to: "place: " in extra field
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
        <xsl:param as="node()" name="tss_reference"/>
        <!--        <xsl:param name="p_individual-notes"/>-->
        <xsl:param name="p_include-attachments"/>
        <xsl:param name="p_include-notes"/>
        <!-- values are: individual, summary, both -->
        <xsl:param as="xs:string" name="p_note-type"/>
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
                        <xsl:text>reference type "</xsl:text>
                        <xsl:value-of select="$v_temp"/>
                        <xsl:text>" not found</xsl:text>
                    </xsl:message>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="v_reference-type-bib">
            <xsl:choose>
                <xsl:when test="$v_reference-type/tei:nym/tei:form[@n = 'bib'] != ''">
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
                <xsl:when test="$v_reference-type/tei:nym/tei:form[@n = 'zotero'] != ''">
                    <xsl:value-of select="$v_reference-type/tei:nym/tei:form[@n = 'zotero']"/>
                </xsl:when>
                <!-- fallback: must be a valid item type for import into Zotero -->
                <xsl:otherwise>
                    <xsl:text>book</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="v_reference-type-sente" select="$v_reference-type/tei:nym/tei:form[@n = 'tss']"/>
        <!--<xsl:variable name="v_reference-is-section" select="if($tss_reference/descendant::tss:characteristic[@name = 'articleTitle'] != '') then(true()) else(false())"/>-->
        <!--<xsl:variable name="v_reference-is-section" select="if($v_reference-type-bib = ('BookSection', 'Article', 'Legislation')) then(true()) else(false())"/>-->
        <xsl:variable name="v_reference-is-section">
            <xsl:choose>
                <xsl:when test="$v_reference-type-bib = ('BookSection', 'Article', 'Legislation')">
                    <xsl:copy-of select="true()"/>
                </xsl:when>
                <xsl:when test="$v_reference-type-bib = ('Book')">
                    <xsl:copy-of select="false()"/>
                </xsl:when>
                <xsl:when test="$tss_reference/descendant::tss:characteristic[@name = 'articleTitle'] != '' and $tss_reference/descendant::tss:characteristic[@name = 'publicationTitle'] != ''">
                    <xsl:copy-of select="true()"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:copy-of select="false()"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="v_reference-is-part-of-series">
            <xsl:choose>
                <xsl:when test="$tss_reference/descendant::tss:characteristic[@name = 'Series'] != ''">
                    <xsl:copy-of select="true()"/>
                </xsl:when>
                <xsl:when test="$tss_reference/descendant::tss:characteristic[@name = 'Collection description'] != ''">
                    <xsl:copy-of select="true()"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:copy-of select="false()"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="v_series">
            <dcterms:isPartOf>
                <bib:Series>
                    <xsl:choose>
                        <xsl:when test="$v_reference-type-sente = 'Photograph'">
                            <xsl:apply-templates mode="m_tss-to-zotero-rdf" select="$tss_reference/descendant::tss:characteristic[@name = 'Collection description']"/>
                            <xsl:apply-templates mode="m_tss-to-zotero-rdf" select="$tss_reference/descendant::tss:characteristic[@name = 'Item']"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:apply-templates mode="m_tss-to-zotero-rdf" select="$tss_reference/descendant::tss:characteristic[@name = 'Series']"/>
                            <xsl:apply-templates mode="m_tss-to-zotero-rdf" select="$tss_reference/descendant::tss:characteristic[@name = 'Series number']"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </bib:Series>
            </dcterms:isPartOf>
        </xsl:variable>
        <!-- debugging -->
        <xsl:if test="$p_debug = true()">
            <xsl:message>
                <xsl:value-of select="$tss_reference/descendant::tss:characteristic[@name = 'UUID']"/>
                <xsl:text> is of type: </xsl:text>
                <xsl:value-of select="$v_reference-type-sente"/>
            </xsl:message>
            <xsl:message>
                <xsl:text>$v_reference-is-section: </xsl:text>
                <xsl:value-of select="$v_reference-is-section"/>
            </xsl:message>
        </xsl:if>
        <!-- output -->
        <xsl:element name="bib:{$v_reference-type-bib}">
            <!-- add an ID -->
            <xsl:attribute name="rdf:about" select="concat('#', $tss_reference/descendant::tss:characteristic[@name = 'UUID'])"/>
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
                                    <!-- volume -->
                                    <xsl:apply-templates mode="m_tss-to-zotero-rdf" select="$tss_reference/descendant::tss:characteristic[@name = 'volume']"/>
                                    <!-- book title -->
                                    <xsl:apply-templates mode="m_tss-to-zotero-rdf" select="$tss_reference/descendant::tss:characteristic[@name = 'publicationTitle']"/>
                                </bib:Book>
                            </xsl:when>
                            <!-- periodical articles -->
                            <xsl:when test="$v_reference-type-bib = 'Article'">
                                <bib:Periodical>
                                    <xsl:apply-templates mode="m_tss-to-zotero-rdf" select="$tss_reference/descendant::tss:characteristic[@name = 'volume']"/>
                                    <xsl:apply-templates mode="m_tss-to-zotero-rdf" select="$tss_reference/descendant::tss:characteristic[@name = 'issue']"/>
                                    <xsl:apply-templates mode="m_tss-to-zotero-rdf" select="$tss_reference/descendant::tss:characteristic[@name = 'publicationTitle']"/>
                                </bib:Periodical>
                            </xsl:when>
                            <!-- maps: it seems that the articleTitle should be mapped to Series -->
                            <xsl:when test="$v_reference-type-zotero = 'map'"/>
                            <xsl:when test="$v_reference-type-zotero = 'webpage'">
                                <z:Website>
                                    <xsl:apply-templates mode="m_tss-to-zotero-rdf" select="$tss_reference/descendant::tss:characteristic[@name = 'publicationTitle']"/>
                                </z:Website>
                            </xsl:when>
                            <!-- fallback: book -->
                            <xsl:otherwise>
                                <bib:Book>
                                    <!-- check if reference is part of a series -->
                                    <xsl:if test="$v_reference-is-part-of-series = true()">
                                        <xsl:copy-of select="$v_series"/>
                                    </xsl:if>
                                    <xsl:apply-templates mode="m_tss-to-zotero-rdf" select="$tss_reference/descendant::tss:characteristic[@name = 'publicationTitle']"/>
                                </bib:Book>
                            </xsl:otherwise>
                        </xsl:choose>
                    </dcterms:isPartOf>
                    <!-- check if an item is part of a series -->
                    <xsl:apply-templates mode="m_tss-to-zotero-rdf" select="$tss_reference/descendant::tss:characteristic[@name = 'articleTitle']"/>
                </xsl:when>
                <!-- fallback: item is stand-alone -->
                <xsl:otherwise>
                    <!-- check if reference is part of a series -->
                    <xsl:if test="$v_reference-is-part-of-series = true()">
                        <xsl:copy-of select="$v_series"/>
                    </xsl:if>
                    <xsl:apply-templates mode="m_tss-to-zotero-rdf" select="$tss_reference/descendant::tss:characteristic[@name = 'publicationTitle']"/>
                    <!-- web pages are seemingly not covered by this policy: they have a page title but the larger website is not necessarily recorded as publicationTitle -->
                    <xsl:if test="not($tss_reference/descendant::tss:characteristic[@name = 'publicationTitle']) and $tss_reference/descendant::tss:characteristic[@name = 'articleTitle']">
                        <xsl:apply-templates mode="m_tss-to-zotero-rdf" select="$tss_reference/descendant::tss:characteristic[@name = 'articleTitle']"/>
                    </xsl:if>
                </xsl:otherwise>
            </xsl:choose>
            <!-- short titles -->
            <xsl:choose>
                <xsl:when test="$tss_reference/descendant::tss:characteristic[@name = 'Short Titel'] != ''">
                    <xsl:apply-templates mode="m_tss-to-zotero-rdf" select="$tss_reference/descendant::tss:characteristic[@name = 'Short Titel']"/>
                </xsl:when>
                <xsl:when test="$tss_reference/descendant::tss:characteristic[@name = 'Shortened title'] != ''">
                    <xsl:apply-templates mode="m_tss-to-zotero-rdf" select="$tss_reference/descendant::tss:characteristic[@name = 'Shortened title']"/>
                </xsl:when>
                <!-- fallback: create a short title -->
                <xsl:otherwise>
                    <xsl:variable name="v_title-temp" select="
                            if ($v_reference-is-section = true()) then
                                ($tss_reference/descendant::tss:characteristic[@name = 'articleTitle'])
                            else
                                ($tss_reference/descendant::tss:characteristic[@name = 'publicationTitle'])"/>
                    <xsl:variable name="v_title-short">
                        <xsl:analyze-string regex="^(.+?)([:|\.|\?])(.+)$" select="$v_title-temp">
                            <xsl:matching-substring>
                                <z:shortTitle>
                                    <xsl:value-of select="regex-group(1)"/>
                                </z:shortTitle>
                            </xsl:matching-substring>
                            <xsl:non-matching-substring>
                                <z:shortTitle>
                                    <xsl:for-each select="tokenize($v_title-temp, '\s')">
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
                    </xsl:variable>
                    <!-- If the reference is an archival source, no short title should be constructed -->
                    <xsl:if test="not(contains($v_reference-type-sente, 'Archival'))">
                        <xsl:copy-of select="$v_title-short"/>
                    </xsl:if>
                </xsl:otherwise>
            </xsl:choose>
            <!-- contributors: authors, editors etc. -->
            <xsl:apply-templates mode="m_tss-to-zotero-rdf" select="$tss_reference/descendant::tss:authors"/>
            <xsl:apply-templates mode="m_tss-to-zotero-rdf" select="$tss_reference/descendant::tss:characteristic[@name = 'Recipient']"/>
            <!-- publisher: name, location -->
            <!-- this should be based on the availability of data -->
            <xsl:copy-of select="oape:bibliography-tss-to-zotero-rdf-publisher($tss_reference)"/>
            <!-- links to notes -->
            <xsl:if test="$p_include-notes = true()">
                <xsl:choose>
                    <xsl:when test="$p_note-type = 'individual'">
                        <xsl:apply-templates mode="m_links" select="$tss_reference/descendant::tss:note"/>
                    </xsl:when>
                    <xsl:when test="$p_note-type = 'summary'">
                        <xsl:apply-templates mode="m_links" select="$tss_reference/descendant::tss:notes"/>
                    </xsl:when>
                    <xsl:when test="$p_note-type = 'both'">
                        <xsl:apply-templates mode="m_links" select="$tss_reference/descendant::tss:notes"/>
                        <xsl:apply-templates mode="m_links" select="$tss_reference/descendant::tss:note"/>
                    </xsl:when>
                </xsl:choose>
            </xsl:if>
            <!-- links to attachment references -->
            <xsl:if test="$p_include-attachments = true()">
                <xsl:apply-templates mode="m_links" select="$tss_reference/descendant::tss:attachmentReference"/>
            </xsl:if>
            <xsl:if test="$tss_reference/descendant::tss:characteristic[@name = 'abstractText'] != ''">
                <dcterms:isReferencedBy rdf:resource="{concat('#',$tss_reference/descendant::tss:characteristic[@name = 'UUID'],'-abstract')}"/>
            </xsl:if>
            <!-- tags, keywords etc. -->
            <xsl:apply-templates mode="m_tss-to-zotero-rdf" select="$tss_reference/descendant::tss:keywords"/>
            <xsl:apply-templates mode="m_tss-to-zotero-rdf" select="$tss_reference/descendant::tss:characteristic[@name = 'status']"/>
            <xsl:apply-templates mode="m_tss-to-zotero-rdf" select="$tss_reference/descendant::tss:characteristic[@name = 'rating']"/>
            <!-- URLs -->
            <xsl:apply-templates mode="m_tss-to-zotero-rdf" select="$tss_reference/descendant::tss:characteristic[@name = 'URL']"/>
            <!-- Identitifiers -->
            <!-- edition -->
            <xsl:apply-templates mode="m_tss-to-zotero-rdf" select="$tss_reference/descendant::tss:characteristic[@name = 'Edition']"/>
            <!-- volume, issue: depends on work not being a chapter or article -->
            <xsl:if test="$v_reference-is-section = false()">
                <xsl:apply-templates mode="m_tss-to-zotero-rdf" select="$tss_reference/descendant::tss:characteristic[@name = 'volume']"/>
                <xsl:apply-templates mode="m_tss-to-zotero-rdf" select="$tss_reference/descendant::tss:characteristic[@name = 'issue']"/>
            </xsl:if>
            <xsl:apply-templates mode="m_tss-to-zotero-rdf" select="$tss_reference/descendant::tss:characteristic[@name = 'pages']"/>
            <!-- publication dates -->
            <xsl:choose>
                <xsl:when test="$tss_reference/descendant::tss:date[@type = 'Publication']">
                    <xsl:apply-templates mode="m_tss-to-zotero-rdf" select="$tss_reference/descendant::tss:date[@type = 'Publication']"/>
                </xsl:when>
                <!-- add an empty node to deal with an import bug in Zotero -->
                <xsl:otherwise>
                    <dc:date/>
                </xsl:otherwise>
            </xsl:choose>
            <!-- Medium -->
            <xsl:apply-templates mode="m_tss-to-zotero-rdf" select="$tss_reference/descendant::tss:characteristic[@name = 'Medium']"/>
            <!-- Archive, repository -->
            <xsl:apply-templates mode="m_tss-to-zotero-rdf" select="$tss_reference/descendant::tss:characteristic[@name = 'Repository']"/>
            <!-- Library catalogue, Standort -->
            <xsl:choose>
                <xsl:when test="$tss_reference/descendant::tss:characteristic[@name = 'Standort'] != ''">
                    <xsl:apply-templates mode="m_tss-to-zotero-rdf" select="$tss_reference/descendant::tss:characteristic[@name = 'Standort']"/>
                </xsl:when>
                <xsl:when test="$tss_reference/descendant::tss:characteristic[@name = 'Web data source'] != ''">
                    <xsl:apply-templates mode="m_tss-to-zotero-rdf" select="$tss_reference/descendant::tss:characteristic[@name = 'Web data source']"/>
                </xsl:when>
            </xsl:choose>
            <!-- call number -->
            <xsl:apply-templates mode="m_tss-to-zotero-rdf" select="$tss_reference/descendant::tss:characteristic[@name = 'Signatur']"/>
            <xsl:apply-templates mode="m_tss-to-zotero-rdf" select="$tss_reference/descendant::tss:characteristic[@name = 'call-num']"/>
            <!-- retrieval date -->
            <xsl:apply-templates mode="m_tss-to-zotero-rdf" select="$tss_reference/descendant::tss:date[@type = 'Retrieval']"/>
            <!-- extra field: map all sorts of custom fields -->
            <dc:description>
                <xsl:apply-templates mode="m_extra-field" select="$tss_reference/descendant::tss:characteristic[@name = 'Citation identifier']"/>
                <!-- dates -->
                <xsl:apply-templates mode="m_extra-field" select="$tss_reference/descendant::tss:characteristic[@name = 'Date Rumi']"/>
                <xsl:apply-templates mode="m_extra-field" select="$tss_reference/descendant::tss:characteristic[@name = 'Date Hijri']"/>
                <xsl:apply-templates mode="m_extra-field" select="$tss_reference/descendant::tss:characteristic[@name = 'Date read']"/>
                <!-- IDs -->
                <xsl:apply-templates mode="m_extra-field" select="$tss_reference/descendant::tss:characteristic[@name = 'DOI']"/>
                <xsl:apply-templates mode="m_extra-field" select="$tss_reference/descendant::tss:characteristic[@name = 'ISBN']"/>
                <xsl:apply-templates mode="m_extra-field" select="$tss_reference/descendant::tss:characteristic[@name = 'OCLCID']"/>

                <!-- original date, title -->
                <xsl:apply-templates mode="m_extra-field" select="$tss_reference/descendant::tss:date[@type = 'Original']"/>
                <xsl:apply-templates mode="m_extra-field" select="$tss_reference/descendant::tss:characteristic[@name = 'Original publication year']"/>
                <xsl:apply-templates mode="m_extra-field" select="$tss_reference/descendant::tss:characteristic[@name = 'Orig.Title']"/>
                <xsl:apply-templates mode="m_extra-field" select="$tss_reference/descendant::tss:characteristic[@name = 'Translated title']"/>
                <xsl:apply-templates mode="m_extra-field" select="$tss_reference/descendant::tss:characteristic[@name = 'issue']"/>
                <!-- make this dependent on the reference type: letter etc. -->
                <xsl:if test="not(contains($v_reference-type-zotero, ('newspaper'))) and not(contains($v_reference-type-zotero, ('book')))">
                    <xsl:apply-templates mode="m_extra-field" select="$tss_reference/descendant::tss:characteristic[@name = 'publicationCountry']"/>
                </xsl:if>
                <xsl:if test="contains($v_reference-type-sente, 'Archival')">
                    <xsl:apply-templates mode="m_extra-field" select="$tss_reference/descendant::tss:characteristic[@name = 'publicationTitle']"/>
                </xsl:if>
                <xsl:apply-templates mode="m_extra-field" select="$tss_reference/descendant::tss:characteristic[@name = 'UUID']"/>
                <xsl:apply-templates mode="m_extra-field" select="$tss_reference/descendant::tss:characteristic[@name = 'volume']"/>
            </dc:description>
            <!-- language -->
            <xsl:apply-templates mode="m_tss-to-zotero-rdf" select="$tss_reference/descendant::tss:characteristic[@name = 'language']"/>
            <!-- abstract -->
            <xsl:apply-templates mode="m_tss-to-zotero-rdf" select="$tss_reference/descendant::tss:characteristic[@name = 'abstractText']"/>
            <!-- ISBN, ISSN etc. -->
            <xsl:apply-templates mode="m_tss-to-zotero-rdf" select="$tss_reference/descendant::tss:characteristic[@name = 'ISBN']"/>
            <!-- number of volumes -->
            <xsl:apply-templates mode="m_tss-to-zotero-rdf" select="$tss_reference/descendant::tss:characteristic[@name = 'Number of volumes']"/>
            <!-- add <z:type> for archival material -->
            <xsl:if test="$v_reference-type-sente = 'Archival File'">
                <xsl:element name="z:type">
                    <xsl:text>File</xsl:text>
                </xsl:element>
            </xsl:if>
            <xsl:if test="$v_reference-type-sente = 'Archival Journal Entry'">
                <xsl:element name="z:type">
                    <xsl:text>Journal entry</xsl:text>
                </xsl:element>
            </xsl:if>
        </xsl:element>
        <!-- notes -->
        <xsl:if test="$p_include-notes = true()">
            <xsl:choose>
                <xsl:when test="$p_note-type = 'individual'">
                    <xsl:apply-templates mode="m_tss-to-zotero-rdf" select="$tss_reference/descendant::tss:note">
                        <xsl:sort order="ascending" select="tss:pages"/>
                    </xsl:apply-templates>
                </xsl:when>
                <xsl:when test="$p_note-type = 'summary'">
                    <xsl:apply-templates mode="m_tss-to-zotero-rdf" select="$tss_reference/descendant::tss:notes"/>
                </xsl:when>
                <xsl:when test="$p_note-type = 'both'">
                    <xsl:apply-templates mode="m_tss-to-zotero-rdf" select="$tss_reference/descendant::tss:notes"/>
                    <xsl:apply-templates mode="m_tss-to-zotero-rdf" select="$tss_reference/descendant::tss:note">
                        <xsl:sort order="ascending" select="tss:pages"/>
                    </xsl:apply-templates>
                </xsl:when>
            </xsl:choose>
        </xsl:if>
        <xsl:apply-templates mode="m_construct-note" select="$tss_reference/descendant::tss:characteristic[@name = 'abstractText']"/>
        <!-- attachments -->
        <xsl:if test="$p_include-attachments = true()">
            <xsl:apply-templates mode="m_tss-to-zotero-rdf" select="$tss_reference/descendant::tss:attachmentReference"/>
        </xsl:if>
    </xsl:function>

    <xsl:function name="oape:bibliography-tss-to-zotero-rdf-publisher">
        <!-- expects tss:reference -->
        <xsl:param name="tss_reference"/>
        <!-- output should be based on the availability of data -->
        <xsl:if test="$tss_reference/descendant::tss:characteristic[@name = ('publicationCountry', 'publisher')]">
            <dc:publisher>
                <foaf:Organization>
                    <vcard:adr>
                        <vcard:Address>
                            <vcard:locality>
                                <xsl:value-of select="$tss_reference/descendant::tss:characteristic[@name = 'publicationCountry']"/>
                            </vcard:locality>
                        </vcard:Address>
                    </vcard:adr>
                    <!-- why would one want to map affiliation to publisher? -->
                    <foaf:name>
                        <xsl:choose>
                            <xsl:when test="$tss_reference/descendant::tss:characteristic[@name = 'publisher']">
                                <xsl:value-of select="$tss_reference/descendant::tss:characteristic[@name = 'publisher']"/>
                            </xsl:when>
                            <!--<xsl:when test="$tss_reference/descendant::tss:characteristic[@name = 'affiliation']">
                            <xsl:value-of select="$tss_reference/descendant::tss:characteristic[@name = 'affiliation']"/>
                        </xsl:when>-->
                        </xsl:choose>
                    </foaf:name>
                </foaf:Organization>
            </dc:publisher>
        </xsl:if>
    </xsl:function>

    <!-- extra field -->
    <xsl:template match="tss:characteristic[@name = 'UUID']" mode="m_extra-field">
        <xsl:value-of select="concat('uuid', $v_separator-key-value, ., $v_new-line)"/>
    </xsl:template>
    <xsl:template match="tss:characteristic[@name = 'DOI']" mode="m_extra-field">
        <xsl:if test=". != ''">
            <xsl:value-of select="concat('doi', $v_separator-key-value, ., $v_new-line)"/>
        </xsl:if>
    </xsl:template>
    <xsl:template match="tss:characteristic[@name = 'ISBN']" mode="m_extra-field">
        <xsl:if test=". != ''">
            <xsl:choose>
                <xsl:when test="ancestor::tss:reference/tss:publicationType/@name = ('Book', 'Book Chapter')"/>
                <xsl:otherwise>
                    <xsl:value-of select="concat('isbn', $v_separator-key-value, ., $v_new-line)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:if>
    </xsl:template>
    <xsl:template match="tss:characteristic[@name = 'ISBN']" mode="m_tss-to-zotero-rdf">
        <dc:identifier>
            <xsl:value-of select="concat('ISBN ', .)"/>
        </dc:identifier>
    </xsl:template>
    <xsl:template match="tss:characteristic[@name = 'OCLCID']" mode="m_extra-field">
        <xsl:if test=". != ''">
            <xsl:value-of select="concat('oclc', $v_separator-key-value, ., $v_new-line)"/>
        </xsl:if>
    </xsl:template>
    <!-- if used with Better BibTeX, one can set the citation key in the extra field -->
    <xsl:template match="tss:characteristic[@name = 'Citation identifier']" mode="m_extra-field">
        <xsl:variable name="v_bibtex-key">
            <xsl:apply-templates select="." mode="m_bibtex"/>
        </xsl:variable>
        <xsl:if test="$v_bibtex-key != ''">
            <xsl:value-of select="concat('Citation Key', $v_separator-key-value, $v_bibtex-key, $v_new-line)"/>
            <xsl:value-of select="concat('BibTeX Key', $v_separator-key-value, $v_bibtex-key, $v_new-line)"/>
        </xsl:if>
    </xsl:template>
    <!-- simple pre-processing template for citation keys -->
    <xsl:template match="tss:characteristic[@name = 'Citation identifier']" mode="m_bibtex">
        <xsl:if test=". != ''">
            <xsl:value-of select="replace(., '\s+', $v_cite-key-whitespace-replacement)"/>
        </xsl:if>
    </xsl:template>
    <xsl:template match="tss:characteristic[@name = 'Date Rumi']" mode="m_extra-field">
        <!-- try to establish the calendar -->
        <xsl:variable name="v_calendar-guessed" select="oape:date-establish-calendar(., 'date', false())"/>
        <xsl:variable name="v_year" select="number(replace(., '^.*(\d{4}).*$', '$1'))"/>
        <xsl:variable name="v_date-normalised">
            <xsl:choose>
                <xsl:when test="$v_calendar-guessed != ''">
                    <xsl:value-of select="oape:date-normalise-input(., 'ar-Latn-x-sente', $v_calendar-guessed)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="."/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <!-- content -->
        <xsl:text>date_</xsl:text>
        <xsl:choose>
            <xsl:when test="$v_calendar-guessed = '#cal_julian'">
                <xsl:text>rumi</xsl:text>
            </xsl:when>
            <xsl:when test="$v_calendar-guessed = '#cal_ottomanfiscal'">
                <xsl:text>mali</xsl:text>
            </xsl:when>
            <xsl:when test="$v_year &lt;= $p_ottoman-fiscal-last-year">
                <xsl:text>mali</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>rumi</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:value-of select="concat($v_separator-key-value, $v_date-normalised, $v_new-line)"/>
    </xsl:template>
    <xsl:template match="tss:characteristic[@name = 'Date Hijri']" mode="m_extra-field">
        <xsl:variable name="v_date-normalised" select="oape:date-normalise-input(., 'ar-Latn-x-sente', '#cal_islamic')"/>
        <xsl:text>date_hijri</xsl:text>
        <xsl:value-of select="concat($v_separator-key-value, $v_date-normalised, $v_new-line)"/>
    </xsl:template>
    <!-- not needed for book,  -->
    <xsl:template match="tss:characteristic[@name = 'issue']" mode="m_extra-field">
        <xsl:if test=". != ''">
            <!--<xsl:choose>
                 <xsl:when test="oape:bibliography-tss-switch-volume-and-issue(ancestor::tss:reference) = false()">
                     <xsl:text>issue</xsl:text>
                 </xsl:when>
                 <xsl:otherwise>
                     <xsl:text>volume</xsl:text>
                 </xsl:otherwise>
             </xsl:choose>-->
            <!-- check if the referene is an archival letter. if so split into Series and Issue number -->
            <xsl:choose>
                <xsl:when test="contains(ancestor::tss:reference/tss:publicationType/@name, 'Letter')">
                    <xsl:analyze-string regex="^([^\d]+)\s+(\d+)\s*$" select=".">
                        <xsl:matching-substring>
                            <xsl:value-of select="concat('collection-title', $v_separator-key-value, regex-group(1), $v_new-line)"/>
                            <xsl:value-of select="concat('collection-number', $v_separator-key-value, regex-group(2), $v_new-line)"/>
                        </xsl:matching-substring>
                        <xsl:non-matching-substring>
                            <xsl:value-of select="concat('issue', $v_separator-key-value, ., $v_new-line)"/>
                        </xsl:non-matching-substring>
                    </xsl:analyze-string>
                </xsl:when>
                <xsl:when test="ancestor::tss:reference/tss:publicationType/@name = ('Book', 'Journal Article')"/>
                <xsl:otherwise>
                    <xsl:value-of select="concat('issue', $v_separator-key-value, ., $v_new-line)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:if>
    </xsl:template>
    <!-- not needed for book,  -->
    <xsl:template match="tss:characteristic[@name = 'volume']" mode="m_extra-field">
        <xsl:if test=". != ''">
            <xsl:choose>
                <xsl:when test="ancestor::tss:reference/tss:publicationType/@name = ('Book', 'Book Chapter', 'Journal Article')">
                    <!--<xsl:message>reference is book, book chapter or journal article; volume will not be mapped to the extra field</xsl:message>-->
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat('volume', $v_separator-key-value, ., $v_new-line)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:if>
    </xsl:template>
    <!-- not needed for book, newspaper article -->
    <xsl:template match="tss:characteristic[@name = 'publicationCountry']" mode="m_extra-field">
        <xsl:if test=". != ''">
            <xsl:choose>
                <xsl:when test="ancestor::tss:reference/tss:publicationType/@name = ('Book', 'Book Chapter')"/>
                <xsl:otherwise>
                    <xsl:value-of select="concat('place', $v_separator-key-value, ., $v_new-line)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:if>
    </xsl:template>
    <xsl:template match="tss:date[@type = 'Original']" mode="m_extra-field">
        <xsl:value-of select="concat('original-date', $v_separator-key-value, oape:date-tss-to-iso(.), $v_new-line)"/>
    </xsl:template>
    <xsl:template match="tss:characteristic[@name = 'Original publication year']" mode="m_extra-field">
        <xsl:if test=". != ''">
            <xsl:value-of select="concat('original-date', $v_separator-key-value, ., $v_new-line)"/>
        </xsl:if>
    </xsl:template>
    <xsl:template match="tss:characteristic[@name = 'Date read']" mode="m_extra-field">
        <xsl:if test=". != ''">
            <xsl:value-of select="concat('date_read', $v_separator-key-value, ., $v_new-line)"/>
        </xsl:if>
    </xsl:template>
    <xsl:template match="tss:characteristic[@name = 'Orig.Title']" mode="m_extra-field">
        <xsl:if test=". != ''">
            <xsl:value-of select="concat('original-title', $v_separator-key-value, ., $v_new-line)"/>
        </xsl:if>
    </xsl:template>
    <xsl:template match="tss:characteristic[@name = 'Translated title']" mode="m_extra-field">
        <xsl:if test=". != ''">
            <xsl:value-of select="concat('translated-title', $v_separator-key-value, ., $v_new-line)"/>
        </xsl:if>
    </xsl:template>

    <!-- contributors -->
    <xsl:template match="tss:authors" mode="m_tss-to-zotero-rdf">
        <!-- the authors should be further differentiated -->
        <xsl:if test="tss:author/@role = ('Author', 'Compiler')">
            <xsl:choose>
                <xsl:when test="ancestor::tss:reference/tss:publicationType/@name = 'Presentation'">
                    <z:presenters>
                        <rdf:Seq>
                            <xsl:apply-templates mode="m_tss-to-zotero-rdf" select="tss:author[@role = ('Author')]"/>
                        </rdf:Seq>
                    </z:presenters>
                </xsl:when>
                <xsl:otherwise>
                    <bib:authors>
                        <rdf:Seq>
                            <xsl:apply-templates mode="m_tss-to-zotero-rdf" select="tss:author[@role = ('Author', 'Compiler')]"/>
                        </rdf:Seq>
                    </bib:authors>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:if>
        <xsl:if test="tss:author/@role = ('Editor', 'Director')">
            <bib:editors>
                <rdf:Seq>
                    <xsl:apply-templates mode="m_tss-to-zotero-rdf" select="tss:author[@role = ('Editor', 'Director')]"/>
                </rdf:Seq>
            </bib:editors>
        </xsl:if>
        <xsl:if test="tss:author/@role = 'Translator'">
            <z:translators>
                <rdf:Seq>
                    <xsl:apply-templates mode="m_tss-to-zotero-rdf" select="tss:author[@role = 'Translator']"/>
                </rdf:Seq>
            </z:translators>
        </xsl:if>
        <xsl:if test="tss:author/@role = 'Contributor'">
            <bib:contributors>
                <rdf:Seq>
                    <xsl:apply-templates mode="m_tss-to-zotero-rdf" select="tss:author[@role = 'Contributor']"/>
                </rdf:Seq>
            </bib:contributors>
        </xsl:if>
        <xsl:if test="tss:author/@role = 'Photographer'">
            <z:artists>
                <rdf:Seq>
                    <xsl:apply-templates mode="m_tss-to-zotero-rdf" select="tss:author[@role = 'Photographer']"/>
                </rdf:Seq>
            </z:artists>
        </xsl:if>
    </xsl:template>
    <xsl:template match="tss:characteristic[@name = 'Recipient']" mode="m_tss-to-zotero-rdf">
        <z:recipients>
            <rdf:Seq>
                <rdf:li>
                    <foaf:Person>
                        <foaf:surname>
                            <xsl:apply-templates/>
                        </foaf:surname>
                    </foaf:Person>
                </rdf:li>
            </rdf:Seq>
        </z:recipients>
    </xsl:template>

    <xsl:template match="tss:author" mode="m_tss-to-zotero-rdf">
        <rdf:li>
            <foaf:Person>
                <xsl:apply-templates mode="m_tss-to-zotero-rdf" select="tss:surname"/>
                <xsl:apply-templates mode="m_tss-to-zotero-rdf" select="tss:forenames"/>
            </foaf:Person>
        </rdf:li>
    </xsl:template>
    <xsl:template match="tss:surname" mode="m_tss-to-zotero-rdf">
        <foaf:surname>
            <xsl:apply-templates/>
        </foaf:surname>
    </xsl:template>
    <xsl:template match="tss:forenames" mode="m_tss-to-zotero-rdf">
        <foaf:givenName>
            <xsl:apply-templates/>
        </foaf:givenName>
    </xsl:template>

    <!-- keywords, tags, status -->
    <!-- there is a need to filter out automatically assigned keywords imported from catalogues -->
    <xsl:template match="tss:keywords" mode="m_tss-to-zotero-rdf">
        <!-- remove duplicate tags -->
        <xsl:variable name="v_keywords">
            <xsl:apply-templates mode="m_tss-to-zotero-rdf" select="tss:keyword[not(contains(@assigner, 'via MARC'))]"/>
        </xsl:variable>
        <!--<xsl:message>
            <xsl:value-of select="$v_keywords"/>
        </xsl:message>-->
        <xsl:for-each-group group-by="." select="$v_keywords/descendant-or-self::dc:subject">
            <xsl:sort order="ascending" select="current-grouping-key()"/>
            <xsl:copy-of select="."/>
        </xsl:for-each-group>
        <!-- add a tag to show that items were imported from Sente -->
        <dc:subject>status: imported from Sente</dc:subject>
    </xsl:template>
    <xsl:template match="tss:keyword" mode="m_tss-to-zotero-rdf">
        <dc:subject>
            <xsl:apply-templates/>
        </dc:subject>
        <!-- add all members of the QuickTag hierarchy -->
        <!-- <tss:keyword assigner="Sente User till" quickTagHierarchy="Economic report|Source|">Economic report</tss:keyword> -->
        <xsl:if test="@quickTagHierarchy != ''">
            <xsl:call-template name="t_convert-quickTags">
                <xsl:with-param name="p_quickTagHierarchy" select="@quickTagHierarchy"/>
                <xsl:with-param name="p_initial-run" select="true()"/>
            </xsl:call-template>
        </xsl:if>
    </xsl:template>
    <xsl:template name="t_convert-quickTags">
        <xsl:param name="p_quickTagHierarchy"/>
        <!--  -->
        <xsl:param name="p_initial-run"/>
        <!-- convert the quickTag hierarchy into a proper node tree -->
        <xsl:param name="p_tag-tree">
            <html:ol>
                <xsl:for-each select="tokenize($p_quickTagHierarchy, '\|')">
                    <xsl:sort order="descending" select="position()"/>
                    <xsl:if test=". != ''">
                        <html:li>
                            <xsl:value-of select="."/>
                        </html:li>
                    </xsl:if>
                </xsl:for-each>
            </html:ol>
        </xsl:param>
        <!-- go one step up in the hierarchy -->
        <xsl:variable name="v_tag-tree-one-level-up">
            <html:ol>
                <xsl:for-each select="$p_tag-tree/descendant::html:li[following-sibling::html:li]">
                    <xsl:copy-of select="."/>
                </xsl:for-each>
            </html:ol>
        </xsl:variable>
        <!-- content: transformed -->
        <xsl:apply-templates mode="m_html-to-zotero-tags" select="$p_tag-tree/html:ol"/>
        <!-- content: each component tag -->
        <xsl:if test="$p_initial-run = true()">
            <xsl:apply-templates mode="m_html-to-zotero-tags" select="$p_tag-tree/html:ol/html:li"/>
        </xsl:if>
        <!-- if there the two variables are different, run this template on the second one -->
        <xsl:if test="not($p_tag-tree = $v_tag-tree-one-level-up)">
            <xsl:call-template name="t_convert-quickTags">
                <xsl:with-param name="p_tag-tree" select="$v_tag-tree-one-level-up"/>
                <xsl:with-param name="p_initial-run" select="false()"/>
            </xsl:call-template>
        </xsl:if>
    </xsl:template>
    <xsl:template match="html:ol" mode="m_html-to-zotero-tags">
        <dc:subject>
            <xsl:for-each select="html:li">
                <!-- the quickTag hierarchy is identified by starting with gt -->
                <!--<xsl:if test="preceding-sibling::html:li">
                    <xsl:text> </xsl:text>
                </xsl:if>
                <xsl:text>> </xsl:text>-->
                <xsl:value-of select="."/>
                <xsl:if test="following-sibling::html:li">
                    <xsl:text> > </xsl:text>
                </xsl:if>
            </xsl:for-each>
        </dc:subject>
    </xsl:template>
    <xsl:template match="html:li" mode="m_html-to-zotero-tags">
        <dc:subject>
            <xsl:value-of select="."/>
        </dc:subject>
    </xsl:template>
    <xsl:template match="tss:characteristic[@name = ('status', 'rating')]" mode="m_tss-to-zotero-rdf">
        <xsl:if test=". != ''">
            <dc:subject>
                <xsl:value-of select="concat(@name, $v_separator-key-value)"/>
                <xsl:value-of select="lower-case(replace(., '\s+', ' '))"/>
            </dc:subject>
        </xsl:if>
    </xsl:template>

    <!-- titles -->
    <xsl:template match="tss:characteristic[@name = ('publicationTitle', 'articleTitle', 'Series', 'Collection description')]" mode="m_tss-to-zotero-rdf">
        <xsl:if test=". != ''">
            <dc:title>
                <xsl:apply-templates/>
            </dc:title>
        </xsl:if>
    </xsl:template>
    <xsl:template match="tss:characteristic[@name = 'publicationTitle'][contains(ancestor::tss:reference/tss:publicationType/@name, 'Archival')]" mode="m_tss-to-zotero-rdf" priority="10">
        <!-- need to test if title is only an automatically formatted reference: indicator is the presence of the call number -->
        <xsl:variable name="v_call-num">
            <xsl:choose>
                <xsl:when test="ancestor::tss:reference/tss:characteristics/tss:characteristic[@name = 'Signatur'] != ''">
                    <xsl:value-of select="ancestor::tss:reference/tss:characteristics/tss:characteristic[@name = 'Signatur']"/>
                </xsl:when>
                <xsl:when test="ancestor::tss:reference/tss:characteristics/tss:characteristic[@name = 'call-num'] != ''">
                    <xsl:value-of select="ancestor::tss:reference/tss:characteristics/tss:characteristic[@name = 'call-num']"/>
                </xsl:when>
            </xsl:choose>
        </xsl:variable>
        <xsl:if test=". != ''">
            <xsl:choose>
                <xsl:when test="$v_call-num != '' and contains(., $v_call-num)">
                    <!-- what should happen in this case? -->
                    <!-- Pull in the issue "number" -->
                    <dc:title>
                        <xsl:apply-templates select="ancestor::tss:reference/tss:characteristics/tss:characteristic[@name = 'issue']"/>
                    </dc:title>
                </xsl:when>
                <xsl:otherwise>
                    <dc:title>
                        <xsl:apply-templates/>
                    </dc:title>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:if>
    </xsl:template>
    <xsl:template match="tss:characteristic[@name = 'publicationTitle'][contains(ancestor::tss:reference/tss:publicationType/@name, 'Archival')]" mode="m_extra-field">
        <!-- need to test if title is only an automatically formatted reference: indicator is the presence of the call number -->
        <xsl:variable name="v_call-num">
            <xsl:choose>
                <xsl:when test="ancestor::tss:reference/tss:characteristics/tss:characteristic[@name = 'Signatur'] != ''">
                    <xsl:value-of select="ancestor::tss:reference/tss:characteristics/tss:characteristic[@name = 'Signatur']"/>
                </xsl:when>
                <xsl:when test="ancestor::tss:reference/tss:characteristics/tss:characteristic[@name = 'call-num'] != ''">
                    <xsl:value-of select="ancestor::tss:reference/tss:characteristics/tss:characteristic[@name = 'call-num']"/>
                </xsl:when>
            </xsl:choose>
        </xsl:variable>
        <xsl:if test=". != ''">
            <xsl:if test="$v_call-num != '' and contains(., $v_call-num)">
                <!-- write Citation to extra field -->
                <xsl:value-of select="concat('Citation', $v_separator-key-value, ., $v_new-line)"/>
            </xsl:if>
        </xsl:if>
    </xsl:template>
    <xsl:template match="tss:characteristic[@name = ('Short Titel', 'Shortened title')]" mode="m_tss-to-zotero-rdf">
        <xsl:if test=". != ''">
            <z:shortTitle>
                <xsl:apply-templates/>
            </z:shortTitle>
        </xsl:if>
    </xsl:template>
    <!-- series numbers, items in collections -->
    <xsl:template match="tss:characteristic[@name = ('Series number', 'Item')]" mode="m_tss-to-zotero-rdf">
        <xsl:if test=". != ''">
            <dc:identifier>
                <xsl:apply-templates/>
            </dc:identifier>
        </xsl:if>
    </xsl:template>
    <!-- transform dates -->
    <xsl:template match="tss:date" mode="m_tss-to-zotero-rdf">
        <xsl:variable name="v_date-formatted" select="oape:date-tss-to-iso(.)"/>
        <xsl:choose>
            <xsl:when test="@type = 'Retrieval'">
                <dcterms:dateSubmitted>
                    <xsl:value-of select="$v_date-formatted"/>
                </dcterms:dateSubmitted>
            </xsl:when>
            <xsl:otherwise>
                <dc:date>
                    <xsl:value-of select="$v_date-formatted"/>
                </dc:date>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="tss:characteristic[@name = 'URL']" mode="m_tss-to-zotero-rdf">
        <dc:identifier>
            <dcterms:URI>
                <rdf:value>
                    <xsl:value-of select="oape:string-clean-urls(.)"/>
                </rdf:value>
            </dcterms:URI>
        </dc:identifier>
    </xsl:template>
    <xsl:template match="tss:characteristic[@name = 'Edition']" mode="m_tss-to-zotero-rdf">
        <prism:edition>
            <xsl:value-of select="."/>
        </prism:edition>
    </xsl:template>
    <xsl:template match="tss:characteristic[@name = 'Number of volumes']" mode="m_tss-to-zotero-rdf">
        <z:numberOfVolumes>
            <xsl:value-of select="."/>
        </z:numberOfVolumes>
    </xsl:template>
    <xsl:template match="tss:characteristic[@name = 'volume']" mode="m_tss-to-zotero-rdf">
        <xsl:if test=". != ''">
            <prism:volume>
                <xsl:value-of select="."/>
            </prism:volume>
        </xsl:if>
    </xsl:template>
    <xsl:template match="tss:characteristic[@name = 'issue']" mode="m_tss-to-zotero-rdf">
        <xsl:if test=". != ''">
            <xsl:choose>
                <xsl:when test="contains(ancestor::tss:reference/tss:publicationType/@name, 'Letter')"/>
                <xsl:otherwise>
                    <prism:number>
                        <xsl:value-of select="."/>
                    </prism:number>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:if>
    </xsl:template>
    <xsl:template match="tss:characteristic[@name = 'pages']" mode="m_tss-to-zotero-rdf">
        <xsl:if test=". != ''">
            <bib:pages>
                <xsl:value-of select="."/>
            </bib:pages>
        </xsl:if>
    </xsl:template>
    <xsl:template match="tss:characteristic[@name = 'language']" mode="m_tss-to-zotero-rdf">
        <xsl:if test=". != ''">
            <z:language>
                <xsl:value-of select="."/>
            </z:language>
        </xsl:if>
    </xsl:template>

    <xsl:template match="tss:characteristic[@name = 'abstractText']" mode="m_tss-to-zotero-rdf">
        <xsl:if test=". != ''">
            <dcterms:abstract>
                <xsl:apply-templates mode="m_html-to-mmd"/>
            </dcterms:abstract>
        </xsl:if>
    </xsl:template>

    <!-- information for locating physical artefact -->
    <xsl:template match="tss:characteristic[@name = 'Repository']" mode="m_tss-to-zotero-rdf">
        <xsl:if test=". != ''">
            <z:archive>
                <xsl:value-of select="."/>
            </z:archive>
        </xsl:if>
    </xsl:template>
    <xsl:template match="tss:characteristic[@name = ('Standort', 'Web data source')]" mode="m_tss-to-zotero-rdf">
        <xsl:if test=". != ''">
            <z:libraryCatalog>
                <xsl:value-of select="."/>
            </z:libraryCatalog>
        </xsl:if>
    </xsl:template>
    <xsl:template match="tss:characteristic[@name = 'Medium']" mode="m_tss-to-zotero-rdf">
        <xsl:if test=". != ''">
            <z:medium>
                <xsl:value-of select="."/>
            </z:medium>
        </xsl:if>
    </xsl:template>

    <!-- call-numbers -->
    <xsl:template match="tss:characteristic[@name = ('call-num')]" mode="m_tss-to-zotero-rdf">
        <xsl:if test=". != ''">
            <dc:subject>
                <dcterms:LCC>
                    <rdf:value>
                        <xsl:apply-templates/>
                    </rdf:value>
                </dcterms:LCC>
            </dc:subject>
        </xsl:if>
    </xsl:template>
    <xsl:template match="tss:characteristic[@name = ('Signatur')]" mode="m_tss-to-zotero-rdf">
        <xsl:if test=". != ''">
            <xsl:choose>
                <!-- for archival reference the call-number should be mapped to location in archive -->
                <xsl:when test="contains(ancestor::tss:reference/tss:publicationType/@name, 'Archival')">
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
        <dcterms:isReferencedBy rdf:resource="{concat('#', oape:get-id(.))}"/>
    </xsl:template>
    <xsl:template match="tss:notes" mode="m_links">
        <dcterms:isReferencedBy rdf:resource="{concat('#',parent::tss:reference/tss:characteristics/tss:characteristic[@name = 'UUID'],'-notes')}"/>
    </xsl:template>
    <xsl:template match="tss:attachmentReference" mode="m_links">
        <link:link rdf:resource="{concat('#', oape:get-id(.))}"/>
    </xsl:template>

    <xsl:function name="oape:get-id">
        <xsl:param name="p_node"/>
        <xsl:choose>
            <xsl:when test="$p_node/@xml:id">
                <xsl:value-of select="$p_node/@xml:id"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="generate-id($p_node)"/>
                <!--                <xsl:value-of select="concat($p_node/ancestor::tss:reference/tss:characteristics/tss:characteristic[@name = 'UUID'], '-note_', count($p_node/preceding-sibling::tss:note))"/>-->
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <!-- notes -->
    <xsl:template match="tss:note" mode="m_tss-to-zotero-rdf">
        <bib:Memo>
            <!-- each note needs an ID -->
            <xsl:attribute name="rdf:about" select="concat('#', oape:get-id(.))"/>
            <rdf:value>
                <xsl:copy-of select="oape:bibliography-tss-note-to-html(.)"/>
            </rdf:value>
            <!-- add tag for colour -->
            <dc:subject>
                <xsl:value-of select="concat('colour_', @color)"/>
            </dc:subject>
            <!-- add tags from SenteAssistant of the pattern $$some note$$ -->
            <xsl:analyze-string regex="\$\$([^\$]+)\$\$" select="tss:comment">
                <xsl:matching-substring>
                    <dc:subject>
                        <xsl:value-of select="regex-group(1)"/>
                    </dc:subject>
                </xsl:matching-substring>
            </xsl:analyze-string>
        </bib:Memo>
    </xsl:template>
    <xsl:template match="tss:notes" mode="m_tss-to-zotero-rdf">
        <xsl:if test="tss:note">
            <bib:Memo>
                <!-- each note needs an ID -->
                <xsl:attribute name="rdf:about" select="concat('#', parent::tss:reference/tss:characteristics/tss:characteristic[@name = 'UUID'], '-notes')"/>
                <rdf:value>
                    <!-- title: there should be a title added here -->
                    <![CDATA[<h1>]]><xsl:text># notes</xsl:text><![CDATA[</h1>]]>
                    <!-- notes -->
                    <xsl:for-each select="tss:note">
                        <xsl:sort data-type="number" order="ascending" select="number(replace(tss:pages, '^§*(\d+).*$', '$1'))"/>
                        <xsl:if test="$p_debug = true()">
                            <xsl:message>
                                <xsl:text>Note on page: </xsl:text>
                                <xsl:value-of select="replace(tss:pages, '^§*(\d+).*$', '$1')"/>
                            </xsl:message>
                        </xsl:if>
                        <xsl:copy-of select="oape:bibliography-tss-note-to-html(.)"/>
                    </xsl:for-each>
                </rdf:value>
            </bib:Memo>
        </xsl:if>
    </xsl:template>
    <xsl:template match="tss:characteristic[@name = 'abstractText']" mode="m_construct-note">
        <xsl:if test=". != ''">
            <bib:Memo>
                <!-- each note needs an ID: use UUID -->
                <xsl:attribute name="rdf:about" select="concat('#', parent::tss:characteristics/tss:characteristic[@name = 'UUID'], '-abstract')"/>
                <rdf:value>
                    <![CDATA[<h1>]]><xsl:text># abstract</xsl:text><![CDATA[</h1>]]>
                    <xsl:apply-templates mode="m_mmd-markup-to-html" select="."/>
                </rdf:value>
                <dc:subject>abstract</dc:subject>
            </bib:Memo>
        </xsl:if>
    </xsl:template>

    <!-- attachments -->
    <xsl:template match="tss:attachmentReference" mode="m_tss-to-zotero-rdf">
        <z:Attachment rdf:about="{concat('#', oape:get-id(.))}">
            <z:itemType>attachment</z:itemType>
            <!-- local URL -->
            <xsl:choose>
                <xsl:when test="tss:URL[@storageMethod = 'Base Directory-Relative, Optionally Alias-Backed']">
                    <xsl:apply-templates mode="m_tss-to-zotero-rdf" select="tss:URL[@storageMethod = 'Base Directory-Relative, Optionally Alias-Backed']"/>
                </xsl:when>
                <xsl:when test="tss:URL[not(@*)]">
                    <xsl:apply-templates mode="m_tss-to-zotero-rdf" select="tss:URL[not(@*)]"/>
                </xsl:when>
            </xsl:choose>
            <!-- date of attachment: will be overwritten upon import -->
            <!--            <dcterms:dateSubmitted>2018-04-03 07:11:40</dcterms:dateSubmitted>-->
            <!-- name -->
            <xsl:apply-templates mode="m_tss-to-zotero-rdf" select="tss:name"/>
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
            <!-- test for local files -->
            <xsl:when test="@storageMethod = 'Base Directory-Relative, Optionally Alias-Backed'">
                <rdf:resource rdf:resource="{.}"/>
            </xsl:when>
            <xsl:when test="starts-with(., 'file:')">
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
        <link:type/>
    </xsl:template>

    <xsl:function name="oape:date-tss-to-iso">
        <xsl:param name="tss_date"/>
        <xsl:variable name="v_year" select="
                if ($tss_date/@year != '') then
                    (format-number($tss_date/@year, '0000'))
                else
                    ('')"/>
        <xsl:variable name="v_month" select="
                if ($tss_date/@month != '') then
                    (format-number($tss_date/@month, '00'))
                else
                    ('xx')"/>
        <xsl:variable name="v_day" select="
                if ($tss_date/@day != '') then
                    (format-number($tss_date/@day, '00'))
                else
                    ('')"/>
        <xsl:variable name="v_date-iso">
            <xsl:value-of select="$v_year"/>
            <xsl:if test="not($v_month = 'xx')">
                <xsl:value-of select="concat('-', $v_month)"/>
            </xsl:if>
            <xsl:if test="not($v_day = '')">
                <xsl:value-of select="concat('-', $v_day)"/>
            </xsl:if>
        </xsl:variable>
        <!-- output -->
        <xsl:value-of select="$v_date-iso"/>
    </xsl:function>

    <xsl:template match="tss:characteristic" mode="m_mmd-markup-to-html">
        <xsl:choose>
            <xsl:when test="html:br">
                <!-- convert everything before the first <br/> -->
                <!-- this seems completely unnecessary -->
                <!--<![CDATA[<p>]]><xsl:apply-templates mode="m_mmd-markup-to-html" select="html:br[1]/preceding-sibling::node()"/><![CDATA[</p>]]>-->
                <!-- convert each group staring with a <br/> -->
                <xsl:for-each-group group-starting-with="html:br" select="child::node()">
                    <xsl:if test="$p_debug = true()">
                        <xsl:message>
                            <xsl:text/>
                            <xsl:value-of select="current-group()"/>
                        </xsl:message>
                    </xsl:if>
                    <xsl:if test="current-group() != ''">
                        <![CDATA[<p>]]><xsl:apply-templates mode="m_mmd-markup-to-html" select="current-group()"/><![CDATA[</p>]]>
                    </xsl:if>
                </xsl:for-each-group>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates mode="m_mmd-markup-to-html"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <!-- in conjunction with the above template this will introduce unnecessary line breaks -->
    <xsl:template match="html:br" mode="m_mmd-markup-to-html"/>
    <xsl:template match="html:*" mode="m_mmd-markup-to-html">
        <xsl:value-of disable-output-escaping="no" select="concat('&lt;', local-name(), '>')"/>
        <!--<![CDATA[<]]><xsl:value-of select="replace(name(),'html:','')"/><![CDATA[>]]>-->
        <xsl:apply-templates mode="m_mmd-markup-to-html"/>
        <xsl:value-of disable-output-escaping="no" select="concat('&lt;/', local-name(), '>')"/>
        <!--<![CDATA[</]]><xsl:value-of select="replace(name(),'html:','')"/><![CDATA[>]]>-->
    </xsl:template>
    <xsl:template match="tei:*" mode="m_mmd-markup-to-html">
        <xsl:value-of disable-output-escaping="no" select="concat('&lt;code>&amp;lt;', name())"/>
        <xsl:if test="@*">
            <xsl:apply-templates mode="m_mmd-markup-to-html" select="@*"/>
        </xsl:if>
        <xsl:choose>
            <xsl:when test=". = ''">
                <xsl:value-of disable-output-escaping="no" select="'/&amp;gt;&lt;/code>'"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of disable-output-escaping="no" select="'&amp;gt;&lt;/code>'"/>
                <xsl:apply-templates mode="m_mmd-markup-to-html"/>
                <xsl:value-of disable-output-escaping="no" select="concat('&lt;code>&amp;lt;/', name(), '&amp;gt;&lt;/code>')"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="tei:*/@*" mode="m_mmd-markup-to-html m_html-to-mmd">
        <xsl:text> </xsl:text>
        <xsl:value-of select="name()"/>
        <xsl:text>="</xsl:text>
        <xsl:value-of select="."/>
        <xsl:text>"</xsl:text>
    </xsl:template>
    <xsl:template match="html:br[not(following-sibling::node()[1] = self::html:br)]" mode="m_html-to-mmd">
        <xsl:value-of select="$v_new-line"/>
        <xsl:choose>
            <!-- list items -->
            <xsl:when test="preceding-sibling::node()[1][matches(., '^\s*[(\-|\+)]')] and following-sibling::node()[1][matches(., '^\s*[(\-|\+)]')]"/>
            <xsl:otherwise>
                <xsl:value-of select="$v_new-line"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="tei:*" mode="m_html-to-mmd">
        <xsl:value-of disable-output-escaping="no" select="concat('&lt;', name())"/>
        <xsl:if test="@*">
            <xsl:apply-templates mode="m_html-to-mmd" select="@*"/>
        </xsl:if>
        <xsl:choose>
            <xsl:when test=". = ''">
                <xsl:value-of disable-output-escaping="no" select="'/&gt;'"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of disable-output-escaping="no" select="'&gt;'"/>
                <xsl:apply-templates mode="m_html-to-mmd"/>
                <xsl:value-of disable-output-escaping="no" select="concat('&lt;/', name(), '&gt;')"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:variable name="v_css-div" select="'display: block; border: 1px solid black;'"/>
    <xsl:function name="oape:bibliography-tss-note-to-html">
        <!-- expects a <tss:note> as input -->
        <xsl:param as="node()" name="tss_note"/>
        <xsl:variable name="v_css-background-color">
            <xsl:text>background-color:</xsl:text>
            <xsl:apply-templates mode="m_tss-notes-to-html" select="$tss_note/@color"/>
            <xsl:text>;</xsl:text>
        </xsl:variable>
        <xsl:variable name="v_pandoc-citation">
            <xsl:text>@</xsl:text>
            <xsl:apply-templates mode="m_bibtex" select="$tss_note/ancestor::tss:reference/tss:characteristics/tss:characteristic[@name = 'Citation identifier']"/>
            <xsl:if test="$tss_note/tss:pages != ''">
                <xsl:text>, </xsl:text>
                <xsl:value-of select="$tss_note/tss:pages"/>
            </xsl:if>
        </xsl:variable>
        <!-- Zotero does not support display of Divs anymore `display: block` has no effect and thus, the background-colour is only used as text highligt. 
             It would therefore make sense to have separator lines and to add the background colour only to the quotation section -->
        <![CDATA[<div style="]]><xsl:value-of select="$v_css-div"/><![CDATA[">]]>
        <!-- add a first line: sorting and display in Zotero -->
        <![CDATA[<p>]]><xsl:apply-templates mode="m_tss-citation" select="$tss_note"/><xsl:text>: </xsl:text><xsl:apply-templates mode="m_tss-summary" select="$tss_note"/><![CDATA[</p>]]>
        <xsl:apply-templates mode="m_tss-notes-to-html" select="$tss_note/tss:title">
            <xsl:with-param name="p_css" select="$v_css-background-color"/>
        </xsl:apply-templates>
        <xsl:apply-templates mode="m_tss-notes-to-html" select="$tss_note/tss:quotation">
            <xsl:with-param name="p_css" select="$v_css-background-color"/>
        </xsl:apply-templates>
        <!-- add pandoc citation -->
        <![CDATA[<p style="text-align: right;">]]>{<xsl:value-of select="$v_pandoc-citation"/>}<![CDATA[</p>]]>
        <xsl:apply-templates mode="m_tss-notes-to-html" select="$tss_note/tss:comment"/>
        <![CDATA[</div>]]>
        <![CDATA[<hr/>]]>
    </xsl:function>
</xsl:stylesheet>
