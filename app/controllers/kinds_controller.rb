class KindsController < ApplicationController
  
  def index
    loadMappingObjects
  end
  
  def edit 
    loadMappingObjects  
    kindId = params[:id]
    @kind = findKind kindId, @kinds
    @crmClasses = orderCrmClassesByNameSimilarity @kind, @crmClasses 
  end
  
  def update
    loadMappingObjects
    korKindId = params[:id]
    kind = findKind korKindId, @kinds
    classNumber = params[:class]
    crmClass = findCRMClass classNumber, @crmClasses
    
    # check if already mapped relations impacted
    if kind.crmClass != nil # only necessary when modification of mapping, not initial mapping
      deleteImpactedActualRelations @relations, kind, crmClass
    end
    kind.crmClass = crmClass
    KorCrmSerializingDeserializing::KorSerializerDeserializer.serializeKindInJason kind
    redirect_to kinds_path
  end
  
  def destroy
    loadMappingObjects
    korKindId = params[:id]
    kind = findKind korKindId, @kinds
    
    # check if already mapped relations impacted
    deleteImpactedActualRelations @relations, kind, nil
  
    kind.crmClass = nil
    KorCrmSerializingDeserializing::KorSerializerDeserializer.serializeKindInJason kind
    redirect_to kinds_path
  end
  
  private
  def deleteImpactedActualRelations relations, kind, crmClass
    impactedActualRelations = Array.new
      for relation in @relations
        for actualRelation in relation.actualRelations
          if (actualRelation.domain.id.to_i.eql? kind.id.to_i) && (crmClass == nil || (!crmClass.isA? actualRelation.domain.crmClass))
            impactedActualRelations.push actualRelation          
          else  
            if (actualRelation.range.id.to_i.eql? kind.id.to_i) && (crmClass == nil || (!crmClass.isA? actualRelation.range.crmClass))
              impactedActualRelations.push actualRelation
            end
          end
        end
      end
      for impactedActualRelation in impactedActualRelations
        impactedActualRelation.chainLinks = Array.new
        KorCrmSerializingDeserializing::KorSerializerDeserializer.serializeRelationInJason impactedActualRelation.relation
      end
  end
 
end
