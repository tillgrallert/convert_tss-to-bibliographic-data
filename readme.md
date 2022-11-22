---
title: "Read me: convert Sente XML (TSS) to bibliographic formats"
author: Till Grallert
date: 2022-11-16
ORCID: orcid.org/0000-0002-5739-8094
---

This repository contains XSLT stylesheets to convert custom Sente/ TSS XML to other, more standard, bibliography formats, namely Zotero RDF (XML)

# Bugs

## import of files into Zotero

in many instances, images files do not make it into Zotero upon import

- *current* **theory**: The failed files all had a `#` in their filename
    + this is standard for multiple attachments renamed by Sente
    + plan:
        * rename all files: replace `\s*\#` with `-file_`
        * change all the paths linking to the files with the same replacement
            - this should be done with XSLT

* example: reference "BD77A86A-C82F-4168-B7F3-4C2D6FAE154E"
* the files **are** available at the location specified in the XML
    - Path: `/Users/Shared/BachUni/BachSources/Sente/BachBibliographie/Bonfils/Album 405 [c 1867-c 1914] Image 116 Vue générale de Sofar et de l'hôtel [c 1867-c 1914]. LEBANON, #2.jpg`
    - XML: `<rdf:resource rdf:resource="/Users/Shared/BachCore/SenteLibrary/BachBibliographie.sente6lib/Contents/Attachments/Bonfils/Album 405 [c 1867-c 1914] Image 116 Vue générale de Sofar et de l'hôtel [c 1867-c 1914]. LEBANON, #2.jpg"/>`
        + the `Attachments/` folder, in this case, is a symlink pointing to the location above
        + changing the path in the Zotero XML **doesn't change** the result

The following are examples of Zotero RDF XML that does not result in imported files. The failed files all had a `#` in their filename.

- uuid: BD77A86A-C82F-4168-B7F3-4C2D6FAE154E

```xml
<z:Attachment xmlns:xs="http://www.w3.org/2001/XMLSchema"
             rdf:about="#uuid_F4F32E0C-BFB2-4AC4-A438-9C4CDED9F192">
    <z:itemType>attachment</z:itemType>
    <rdf:resource rdf:resource="/Users/Shared/BachUni/BachSources/Sente/BachBibliographie/Bonfils/Album 405 [c 1867-c 1914] Image 116 Vue générale de Sofar et de l'hôtel [c 1867-c 1914]. LEBANON, #2.jpg"/>
    <dc:title>Scan 1</dc:title>
    <z:linkMode>2</z:linkMode>
</z:Attachment>
```

- uuid: 4135A6A8-F7D8-48DA-A0AF-DDBB2EB9D5B1
    + the first file made
    + the second did not

```xml
<z:Attachment xmlns:xs="http://www.w3.org/2001/XMLSchema"
             rdf:about="#uuid_2841851E-BD71-49E4-9599-8470F051A30B">
    <z:itemType>attachment</z:itemType>
    <rdf:resource rdf:resource="/Users/Shared/BachCore/SenteLibrary/BachBibliographie.sente6lib/Contents/Attachments/! Unknown Author(s)/damaskus bahnhof kadem foto ak i ii.jpg"/>
    <dc:title/>
    <z:linkMode>2</z:linkMode>
</z:Attachment>
<z:Attachment xmlns:xs="http://www.w3.org/2001/XMLSchema"
             rdf:about="#uuid_7283E593-207F-41DB-A26E-5128C6FCE228">
    <z:itemType>attachment</z:itemType>
    <rdf:resource rdf:resource="/Users/Shared/BachCore/SenteLibrary/BachBibliographie.sente6lib/Contents/Attachments/! Unknown Author(s)/damaskus bahnhof kadem foto ak i ii #2.jpg"/>
    <dc:title/>
    <z:linkMode>2</z:linkMode>
</z:Attachment>
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
