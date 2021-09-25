% construct a ReqIfUtil object by providing a reqif file
reqif = ReqIfUtil('ReqsAndLinks.reqif');

% Basic stuffs. 
%--------------
%Count specifications/specObjects/specRelations
num = reqif.getSpecObjCount();
disp(['There are ' num2str(num) ' SpecObjects']);
num = reqif.getSpecRelationCount();
disp(['There are ' num2str(num) ' SpecRelations']);
num = reqif.getSpecificationCount();
disp(['There are ' num2str(num) ' Specifications']);

% Advanced stuffs. 
%-----------------
% 1.Find and replace
% ReqIF.ChapterName normally is mapped to requirement summary.
specObjs = ReqIfUtil.find(reqif, 'ReqIF.ChapterName', 'Req1');
num = length(specObjs);
disp(['Found ' num2str(num) ' SpecObjects with summary as Req1']);
% change its value from Req1 to ReqNew
ReqIfUtil.setValue(specObjs{1}, 'ReqIF.ChapterName', 'ReqNew');
% save a new copy
reqif.saveReqIf('saved.reqif');

% 2. Find and add a link. 
% Find two SpecObjects and add a SpecRelation between them 
specObj1 = ReqIfUtil.find(reqif, 'ReqIF.ChapterName', 'Req5');
specObj2 = ReqIfUtil.find(reqif, 'ReqIF.ForeignID', ':6');
% Add a link from specObj1 to specObj2 named "Implement"
reqif.addRelation(specObj1{1}, specObj2{1}, 'Implement');
% save a new copy
reqif.saveReqIf('addedLink.reqif');

% 3. Read the new ReqIf and check the number of links
reqifNew = ReqIfUtil('addedLink.reqif');
% there shall be three links now.
num = reqifNew.getSpecRelationCount();
disp(['There shall be ' num2str(num) ' SpecRelations']);
