class RelationsController < ApplicationController
  
  def index
    @relations = KorCrmMapping::KorSerializerDeserializer.deserializeRelationsInJason
    kinds = KorCrmMapping::KorSerializerDeserializer.deserializeKindsInJason
    crmClasses = KorCrmMapping::CrmSerializerDeserializer.deserializeClassesInJason
    crmProperties = KorCrmMapping::CrmSerializerDeserializer.deserializePropertiesInJason
    for relation in @relations
      relation.reestablishLinks kinds, crmClasses, crmProperties
    end
  end
  
  def edit
    relationId = params[:relationId]
    domainId = params[:domainId]
    rangeId = params[:rangeId]
    @relations = KorCrmMapping::KorSerializerDeserializer.deserializeRelationsInJason
    kinds = KorCrmMapping::KorSerializerDeserializer.deserializeKindsInJason
    crmClasses = KorCrmMapping::CrmSerializerDeserializer.deserializeClassesInJason
    crmProperties = KorCrmMapping::CrmSerializerDeserializer.deserializePropertiesInJason
    
    actualRelationFound = false
    i = 0
    while i < @relations.size && !actualRelationFound
      j = 0
      while j < @relations[i].actualRelations.size && !actualRelationFound
        if (@relations[i].actualRelations[j].domainId.to_i == domainId.to_i) && (@relations[i].actualRelations[j].rangeId.to_i == rangeId.to_i)
          actualRelationFound = true
          @actualRelation = @relations[i].actualRelations[j]
          @actualRelation.reestablishLinks kinds, crmClasses, crmProperties
          @actualRelation.domain.reestablishLinks crmClasses
          @actualRelation.range.reestablishLinks crmClasses
        end
        j+=1
      end
      i+=1
    end
    if @actualRelation.domain == nil
      #TODO
    end
    if @actualRelation.range == nil
      #TODO
    end
  end
  
  def update
    redirect_to relations_path
  end
  
end
