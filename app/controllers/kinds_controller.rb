class KindsController < ApplicationController
  
  def index
    loadMappingObjects
  end
  
  def edit 
    loadMappingObjects  
    kindId = params[:id]
    @kind = findKind kindId, @kinds
  end
  
  def update
    loadMappingObjects
    korKindId = params[:id]
    kind = findKind korKindId, @kinds
    classNumber = params[:class]
    crmClass = findCRMClass classNumber, @crmClasses
    
    # check if already mapped relations impacted
    impactedActualRelations = Array.new
    for relation in @relations
      for actualRelation in relation.actualRelations
        if actualRelation.domain.id.to_i.eql? kind.id.to_i
        end
        if (actualRelation.domain.id.to_i.eql? kind.id.to_i) && (!crmClass.isA? actualRelation.domain.crmClass)
          impactedActualRelations.push actualRelation          
        else  
          if actualRelation.range.id.to_i.eql? kind.id.to_i
          end
          if (actualRelation.range.id.to_i.eql? kind.id.to_i) && (!crmClass.isA? actualRelation.range.crmClass)
            impactedActualRelations.push actualRelation
          end
        end
      end
    end
    for impactedActualRelation in impactedActualRelations
      impactedActualRelation.chainLinks = Array.new
      KorCrmMapping::KorSerializerDeserializer.serializeRelationInJason impactedActualRelation.relation
    end
    
    kind.crmClass = crmClass
    KorCrmMapping::KorSerializerDeserializer.serializeKindInJason kind
    redirect_to kinds_path
  end
 
end
