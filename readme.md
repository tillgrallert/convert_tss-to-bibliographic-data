---
title: "Read me: convert Sente XML (TSS) to bibliographic formats"
author: Till Grallert
date: 2020-08-06
ORCID: orcid.org/0000-0002-5739-8094
---

This repository contains XSLT stylesheets to convert custom Sente/ TSS XML to other, more standard, bibliography formats, namely Zotero RDF (XML)

# to do

- some fields and reference types are not yet mapped
- reference types

# features
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
