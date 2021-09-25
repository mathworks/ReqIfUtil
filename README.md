# MATLAB utility for Requirements Interchange Format (ReqIF) files

This is a MATLAB&reg; class for manipulating [ReqIF&trade;](https://www.omg.org/spec/ReqIF/1.2/About-ReqIF/) documents.
ReqIF stands for Requirements Interchange Format. It is an important format that enables data exchange between requirement
management tools. 
 
With ReqIfUtil, you can
* open a ReqIF document
* get basic information like count of SpecObjects, Specifications, and SpecRelations
* find SpecObject using attribute name and attribute value
* change an attribute value of a SpecObject
* add a SpecRelation between SpecObjects

# Usage

## Open and Save
To open a ReqIF document, instantiate a ReqIfUtil object with the filename. Here the sample ReqIF 
"ReqsAndLinks.reqif" is used for example:

```
reqif = ReqIfUtil('ReqsAndLinks.reqif');
```
To save a copy, call this:

```
reqif.saveReqIf('SavedReqIf.reqif');
```

## Basic information of ReqIf
To get basic information of the opened ReqIF document:

```
numSpecObjs = reqif.getSpecObjCount();
numSpecRelations = reqif.getSpecRelationCount();
numSpecifications = reqif.getSpecificationCount();
```

## Find SpecObjects
Find SpecObjects using attribute name and attribute value. For example, ReqIF.ChapterName is in general mapped to
requirement summary. This sample code looks for SpecObjects that have "ReqIF.ChapterName" as "Req1"

```
specObjs = ReqIfUtil.find(reqif, 'ReqIF.ChapterName', 'Req1');
```

## Change attribute value of a SpecObject

```
ReqIfUtil.setValue(specObjs{1}, 'ReqIF.ChapterName', 'ReqNew');
```

## Add a SpecRelation
Assume that you found the two SpecObjects (source being specObj1, and target being specObj2) using the find methods above or you just pick two. Now you want to
add a SpecRelation:

```
reqif.addLink(specObj1, specObj2, 'Implement');
```

# How to get started
First copy the ReqIfUtil.m and ReqsAndLinks.reqif to your working directory. 
```
% construct a ReqIfUtil object by providing a reqif file
reqif = ReqIfUtil('ReqsAndLinks.reqif');
% find two spec-objects
specObj1 = ReqIfUtil.find(reqif, 'ReqIF.ChapterName', 'Req5');
specObj2 = ReqIfUtil.find(reqif, 'ReqIF.ForeignID', ':6');
% Add a link from specObj1 to specObj2 named "Implement"
reqif.addRelation(specObj1{1}, specObj2{1}, 'Implement');
% save a new copy
reqif.saveReqIf('addedLink.reqif');
```
Please refer to [testReqIfUtil.m](./testReqIfUtil.m) for more examples of using
ReqIfUtil.
