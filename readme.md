---
title: "Read me: convert Sente XML (TSS) to bibliographic formats"
author: Till Grallert
date: 2020-08-06
ORCID: orcid.org/0000-0002-5739-8094
---

This repository contains XSLT stylesheets to convert custom Sente/ TSS XML to other, more standard, bibliography formats, namely Zotero RDF (XML)

# Bugs

- [x] Generating Notes from abstracts:  if there is a `<html:br>` element, the first paragraph is repeated. This seems to be a bug in the `m_mmd-markup-to-html` mode. I suppose, I had incorrectly understood the `@group-starting-with` attribute on `xsl:for-each-group`.
	
```xsl
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
```


# to do

- [ ] chunk output into files with 1000 references for easier import into Zotero
- [ ] some fields and reference types are not yet mapped
	+ [x] photographer -> `z:artists`
- [ ] reference types
	+ [ ] **Sālnāmes**: 
		* should be classified as books. 
		* volume should become series number
		* this can be done manually once after import into Zotero, as Salnames acount for not more than 50 references

# features
## citation keys

The Sente "Citation Identifier" is converted to BibTeX cite keys and added to Zotero's extra field to be used with the "Better BibTeX" add-on as

```
Citation Key: value
BibTeX Key: value
```

Any whitespace in the "Citation identifier" is replaced with a character string specified in the variable `$v_cite-key-whitespace-replacement`.

## abstracts

abstracts are converted to Zotero notes and tagged with `<dc:subject>abstract</dc:subject>`

## notes

notes are converted to Zotero notes. They retain the layout and colour of notes in Sente and are explicitly tagged with the colour:

1. as individual Zotero notes and
2. as one Zotero note collecting all Sente notes

SenteAssistant Tags of the plain text pattern `$$.+?$$` are converted to proper tags on Zotero notes, using regex: `\$\$([^\$]+)\$\$` translates to `<dc:subject>$1</dc:subject>`

## quickTag hierarchy

all the tags from the QuickTag hierarchy are actively assigned as Zotero Tags:

+ a reference tagged in my own custom Sente XML with

```xml
<tss:keyword assigner="Sente User Sebastian" quickTagHierarchy="Social history|History|Methodology/theory|">Social history</tss:keyword>
```

+ will be tagged in Zotero RDF as

```xml
<dc:subject>Social history</dc:subject>
<dc:subject>History</dc:subject>
<dc:subject>> Methodology/theory</dc:subject>
<dc:subject>> Methodology/theory > History</dc:subject>
<dc:subject>> Methodology/theory > History > Social history</dc:subject>
```
