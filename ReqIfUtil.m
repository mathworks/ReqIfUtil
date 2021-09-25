classdef ReqIfUtil < handle
    
    % Copyright 2021 The MathWorks, Inc.

    properties (Access=public)
        reqIfFile;
        outfile;
        mfReqIfObj;
    end
    
    properties (Access=private)
        mfModel;
        uuid_count;
    end
    
     methods (Access=public)
        function reqIf = ReqIfUtil(reqIfFile)
            reqIf.reqIfFile = reqIfFile;
            reqIf.mfModel = mf.zero.Model();
            reqIf.openReqIf();
            reqIf.uuid_count = 1;
        end
        
        %---- Open and Save ----------------
        function openReqIf(obj)
            xmlContent = slreq.utils.readFromXML(obj.reqIfFile);
            reqIfData = slreq.reqif.ReqIfData(obj.mfModel);
            obj.mfReqIfObj = reqIfData.parse(xmlContent);
        end
        
        function saveReqIf(obj, outfile)
            function done=cleanup(~, value)
                done = false;
                def = value.definition;
                if isa(def, 'slreq.reqif.AttributeDefinitionXhtml')
                    val = value.theValue;
                    val.setPropertyValue('theValue', '');
                end
            end
            specObjs = obj.mfReqIfObj.coreContent.specObjects.toArray();
            for i=1:length(specObjs)
                specObj = specObjs(i);
                ReqIfUtil.applyToValues(specObj, @cleanup);
            end
            
            mdl = mf.zero.Model;
            rIfData = slreq.reqif.ReqIfData(mdl);

            xml = rIfData.serialize(obj.mfReqIfObj, 'REQIF');
            slreq.utils.writeToXML(outfile, xml);
        end
        
        %---- Some utilities ----------------
        function count = getSpecObjCount(obj)
            specObjs = obj.mfReqIfObj.coreContent.specObjects.toArray();
            count = length(specObjs);
        end
        function count = getSpecRelationCount(obj)
            specRelations = obj.mfReqIfObj.coreContent.specRelations.toArray();
            count = length(specRelations);
        end
        function count = getSpecificationCount(obj)
            specifications = obj.mfReqIfObj.coreContent.specifications.toArray();
            count = length(specifications);
        end
        function specRelationType = getSpecRelType(obj, relName)
            specRelationType = [];
            specTypes = obj.mfReqIfObj.coreContent.specTypes.toArray();
            for i=1:length(specTypes)
                specType = specTypes(i);
                if isa(specType, 'slreq.reqif.SpecRelationType')
                   if strcmp(specType.longName, relName)
                        specRelationType = specType;
                        break;
                   end
                end
            end
            if isempty(specRelationType)
                % Not found. Just create a simple one.
                specRelationType =slreq.reqif.SpecRelationType(obj.mfModel);
                specRelationType.identifier = obj.getUUID();
                specRelationType.longName = relName;
                obj.mfReqIfObj.coreContent.specTypes.add(specRelationType);
            end
        end
        
        function spec = findSpecification(obj, specObj)
            spec = [];
            function found = findInSpec(~, specHierarchy)
                found = false;
                if strcmp(specHierarchy.object.identifier, specObj.identifier)
                    found = true;
                end
            end
            specifications = obj.mfReqIfObj.coreContent.specifications.toArray();
            for i=1:length(specifications)
                specification = specifications(i);
                found = ReqIfUtil.traverseSpecHierarchy(specification, @findInSpec);
                if found
                    spec = specification;
                    break;
                end
            end
                
        end
        
        function relationGroupType = findRelGroupType(obj)
           % Use only one relation group type
           relationGroupType = [];
           specTypes = obj.mfReqIfObj.coreContent.specTypes.toArray();
           for i=1:length(specTypes)
               specType = specTypes(i);
               if isa(specType, 'slreq.reqif.RelationGroupType')
                   relationGroupType = specType;
                   break;
               end
           end
           if isempty(relationGroupType)
              relationGroupType = slreq.reqif.RelationGroupType(obj.mfModel);
              relationGroupType.identifier = obj.getUUID();
              obj.mfReqIfObj.coreContent.specTypes.add(relationGroupType);
           end
        end
        
        function relationGroup = findRelationGroup(obj, spec1, spec2)
            relationGroup = [];
            relGroups = obj.mfReqIfObj.coreContent.specRelationGroups.toArray();
            for i=1:length(relGroups)
                relGroup = relGroups(i);
                if ReqIfUtil.isSame(spec1, relGroup.sourceSpecification) && ...
                        ReqIfUtil.isSame(spec2, relGroup.targetSpecification)
                    relationGroup = relGroup;
                    break;
                end
            end
            
            if isempty(relationGroup)
                relationGroup = slreq.reqif.RelationGroup(obj.mfModel);
                relationGroup.identifier = obj.getUUID();
                relationGroup.type = obj.findRelGroupType();
                relationGroup.sourceSpecification = spec1;
                relationGroup.targetSpecification = spec2;
                obj.mfReqIfObj.coreContent.specRelationGroups.add(relationGroup);
            end
        end
        
        function addRelation(obj, specObj1, specObj2, relName)
            % SpecRelation
            specRelationType = obj.getSpecRelType(relName);
            newRelation = slreq.reqif.SpecRelation(obj.mfModel);
            newRelation.type = specRelationType;
            newRelation.source = specObj1;
            newRelation.target = specObj2;
            newRelation.identifier = obj.getUUID();
            obj.mfReqIfObj.coreContent.specRelations.add(newRelation);
            
            % SpecRelationGroup
            spec1 = obj.findSpecification(specObj1);
            spec2 = obj.findSpecification(specObj2);
            relGroup = obj.findRelationGroup(spec1, spec2);
            relGroup.specRelations.add(newRelation);
        end
        function uuid=getUUID(obj)
            % only unique within this ReqIf
            uuid = ['_cac59cfc-f269-11eb-9a03-0242ac130003_' num2str(obj.uuid_count)];
            obj.uuid_count = obj.uuid_count + 1;    
        end

    end
    
    methods (Static)
        function done = traverseSpecHierarchy(parent, func)
            
            specHs = parent.children.toArray();
            for i=1:length(specHs)
                specHierarchy = specHs(i);
                done = func(parent, specHierarchy);
                if done
                    break;
                else
                    ReqIfUtil.traverseSpecHierarchy(specHierarchy, func);
                end
            end
        end
         
        function applyToValues(specObj, func)
            values = specObj.values.toArray();
            for j=1:numel(values)
                value = values(j);
                done = func(specObj, value);
                if (done)
                    break;
                end
           end
        end
            
        function specObjs = find(src, attrName, attrValue)
            fromObjs = [];
            if isa(src, 'ReqIfUtil')
                fromObjs = src.mfReqIfObj.coreContent.specObjects.toArray();
            elseif ~isscalar(src) && isa(src, 'ReqIfUtil')
                fromObjs = src;
            end
                       
            specObjs = {};
            
            % nested function
            function done = processSpecObjValue(specObj, value)
                done = false;
                name = value.definition.longName;
                if strcmp(name, attrName)
                    if isa(attrValue, 'double')
                        if value.theValue == attrValue
                            done = true;
                            specObjs(end+1) = specObj;
                        end
                    elseif isa(attrValue, 'char') 
                        if strcmp(value.theValue, attrValue)
                            done = true;
                            specObjs{end+1} = specObj;
                        end
                    end
                end
            end
            
            for i=1:length(fromObjs)
                fromObj = fromObjs(i);
                ReqIfUtil.applyToValues(fromObj, @processSpecObjValue); 
            end
        end
         
        function setValue(specObj, attrName, attrValue)
             function done = setValue(~, value)
                done = false;
                name = value.definition.longName;
                if strcmp(name, attrName)
                    value.theValue = attrValue;
                    done = true;
                end
             end
             ReqIfUtil.applyToValues(specObj, @setValue);
        end
        function tf = isSame(obj1, obj2)
            tf = strcmp(obj1.identifier, obj2.identifier);
        end 
    end
    
end
