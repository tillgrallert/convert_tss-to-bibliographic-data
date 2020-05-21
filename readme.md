---
title: "Read me: convert Sente XML (TSS) to bibliographic formats"
author: Till Grallert
date: 2020-05-20 21:18:46 +0200
ORCID: orcid.org/0000-0002-5739-8094
---

This repository contains XSLT stylesheets to convert custom Sente/ TSS XML to other, more standard, bibliography formats, namely Zotero RDF (XML)

# to do

- write XSLT that explicitly assigns all the tags from the QuickTag hierarchy,
    + i.e. a reference tagged in Sente XML with

    ```xml
    <tss:keyword assigner="Sente User Sebastian" quickTagHierarchy="Social history|History|Methodology/theory|">Social history</tss:keyword>
    ```

    + should be tagged in Zotero RDF as

    ```xml
    <dc:subject>Social history</dc:subject>
    <dc:subject>History</dc:subject>
    <dc:subject>> Methodology/theory</dc:subject>
    <dc:subject>> Methodology/theory > History</dc:subject>
    <dc:subject>> Methodology/theory > History > Social history</dc:subject>
    ```
