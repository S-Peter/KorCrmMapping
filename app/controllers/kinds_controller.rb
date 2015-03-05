class KindsController < ApplicationController
  
  def index
    loadMappingObjects
  end
  
  def edit 
    loadMappingObjects  
    kindId = params[:id]
    @kind = findKind kindId, @kinds
    for crmClass in @crmClasses
      normalizedLevenshteinDistance = KorCrmMapping::EditDistanceCalculator.calculateNormalizedLevenshteinDistance @kind.name, crmClass.label
      crmClass.distanceValue = normalizedLevenshteinDistance
    end  
    puts "Before sorting"
    for crmClass in @crmClasses
      puts crmClass.distanceValue 
    end
    puts "After sorting"
    @crmClasses.sort_by! {|cClass| -cClass.distanceValue} 
    for crmClass in @crmClasses
      puts crmClass.distanceValue 
    end
  end
  
  def update
    loadMappingObjects
    korKindId = params[:id]
    kind = findKind korKindId, @kinds
    classNumber = params[:class]
    crmClass = findCRMClass classNumber, @crmClasses
    
    # check if already mapped relations impacted
    if kind.crmClass != nil # only necessary when modification of mapping, not initial mapping
      impactedActualRelations = Array.new
      for relation in @relations
        for actualRelation in relation.actualRelations
          if (actualRelation.domain.id.to_i.eql? kind.id.to_i) && (!crmClass.isA? actualRelation.domain.crmClass)
            impactedActualRelations.push actualRelation          
          else  
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
    end
    kind.crmClass = crmClass
    KorCrmMapping::KorSerializerDeserializer.serializeKindInJason kind
    redirect_to kinds_path
  end
  
  def destroy
    loadMappingObjects
    korKindId = params[:id]
    kind = findKind korKindId, @kinds
    
    # check if already mapped relations impacted
    impactedActualRelations = Array.new
    for relation in @relations
      for actualRelation in relation.actualRelations
        if (actualRelation.domain.id.to_i.eql? kind.id.to_i)
          impactedActualRelations.push actualRelation          
        else  
          if (actualRelation.range.id.to_i.eql? kind.id.to_i)
            impactedActualRelations.push actualRelation
          end
        end
      end
    end
    for impactedActualRelation in impactedActualRelations
      impactedActualRelation.chainLinks = Array.new
      KorCrmMapping::KorSerializerDeserializer.serializeRelationInJason impactedActualRelation.relation
    end
    
    kind.crmClass = nil
    KorCrmMapping::KorSerializerDeserializer.serializeKindInJason kind

    redirect_to kinds_path
  end
 
end
