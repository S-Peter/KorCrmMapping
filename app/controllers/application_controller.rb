class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  
  protected
  def loadMappingObjects
    @crmClasses = KorCrmMapping::CrmSerializerDeserializer.deserializeClassesInJason
    for crmClass in @crmClasses
      crmClass.reestablishLinks @crmClasses
    end
    @crmProperties = KorCrmMapping::CrmSerializerDeserializer.deserializePropertiesInJason
    for crmProperty in @crmProperties
      crmProperty.reestablishLinks @crmProperties, @crmClasses
    end
    @kinds = KorCrmMapping::KorSerializerDeserializer.deserializeKindsInJason
    for kind in @kinds
      kind.reestablishLinks @crmClasses
    end
    @relations = KorCrmMapping::KorSerializerDeserializer.deserializeRelationsInJason
    for relation in @relations
      relation.reestablishLinks @kinds, @crmClasses, @crmProperties
    end
  end
  
  protected
  def findKind (kindId, kinds)
    kindFound = false
    i = 0
    while i < kinds.size && !kindFound
      if kinds[i].id.to_i == kindId.to_i
        kind = kinds[i]
        kindFound = true
      end
      i += 1
    end
    kind
  end
  
  protected
  def findCRMClass (crmClassNumber, crmClasses)
    crmClassFound = false
    i = 0
    while i < crmClasses.size && !crmClassFound
      if crmClasses[i].number.to_i == crmClassNumber.to_i
        crmClass = crmClasses[i]
        crmClassFound = true
      end
      i += 1
    end
    crmClass
  end
  
  protected
  def findActualRelation (relations, relationId, domainId, rangeId)
    actualRelationFound = false
    i = 0
    while i < relations.size && !actualRelationFound
      if relations[i].id.to_i == relationId.to_i
        j = 0
        while j < relations[i].actualRelations.size && !actualRelationFound
          if (relations[i].actualRelations[j].domainId.to_i == domainId.to_i) && (relations[i].actualRelations[j].rangeId.to_i == rangeId.to_i)
            actualRelationFound = true
            actualRelation = relations[i].actualRelations[j]
          end
          j+=1
        end
      end
      i+=1
    end
    actualRelation
  end
  
end
