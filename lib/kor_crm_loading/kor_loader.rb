require 'json'

module KorCrmLoading::KorLoader
  
  def self.loadKor
    @@kinds = Kind.all
    @@relations = Relation.all
    deriveActualRelationsFromRelationships
    
    @@maxKindID = 0
    for kind in @@kinds
      if kind.id > @@maxKindID
        @@maxKindID = kind.id
      end
    end
    @@lastFieldKindID = @@maxKindID
    
    @@maxRelationID = 0
    for relation in @@relations
      if relation.id > @@maxRelationID
        @@maxRelationID = relation.id
      end
    end
    @@lastFieldRelationID = @@maxRelationID
    
    addAdditionalKindsAndRelationsFromNameFields
    addAdditionalKindsAndRelationsFromDateFields
    #addAdditionalKindsAndRelationsFromDynamicFields #TODO
    KorCrmSerializingDeserializing::KorSerializerDeserializer.serializeKindsInJason @@kinds
    KorCrmSerializingDeserializing::KorSerializerDeserializer.serializeRelationsInJason @@relations
  end
  
  private
  def self.deriveActualRelationsFromRelationships
    relationshipsGroupedByActualRelations = Relationship.
    joins("LEFT JOIN entities as froms on froms.id = relationships.from_id").
    joins("LEFT JOIN entities as tos on tos.id = relationships.to_id").
    group("relationships.relation_id", "froms.kind_id", "tos.kind_id")
    
    for relationshipGroupedByActualRelations in relationshipsGroupedByActualRelations do  
      relation = @@relations.find do |re|
        re.id.to_i == Relationship.find(relationshipGroupedByActualRelations.id).relation_id.to_i
      end
      domain = @@kinds.find do |d|
        d.id.to_i == Entity.find(relationshipGroupedByActualRelations.from_id).kind_id.to_i
      end
      range = @@kinds.find do |ra|
        ra.id.to_i == Entity.find(relationshipGroupedByActualRelations.to_id).kind_id.to_i
      end
  
      if relation && domain && range
        actualRelation = ActualRelation.new
        actualRelation.relation = relation
        actualRelation.domain = domain
        actualRelation.range = range
        actualRelations = relation.actualRelations
        if actualRelations == nil
          actualRelations = Array.new
          actualRelations.push actualRelation
          relation.actualRelations = actualRelations
        else
          actualRelations.push actualRelation
        end
      end
    end
  end
  
  private
  def self.addAdditionalKindsAndRelationsFromNameFields
    @@lastFieldKindID += 1
    name = Kind.new
    name.id = @@lastFieldKindID
    name.name = "Name"
    name.description = "Name der Entitaet"
    
    @@lastFieldRelationID += 1
    hasName = Relation.new
    hasName.id = @@lastFieldRelationID
    hasName.name = "hat Namen"
    hasName.reverse_name = "ist Name von"
    hasName.description = "Entitaet - Name"
    hasName.actualRelations = Array.new
    for kind in @@kinds
      if kind.id <= @@maxKindID # i.e. original kind
        actualRelation = ActualRelation.new
        actualRelation.relation = hasName
        actualRelation.domain = kind
        actualRelation.range = name
        hasName.actualRelations.push actualRelation
      end
    end
    
    @@kinds.push name
    @@relations.push hasName
  end
  
  private
  def self.addAdditionalKindsAndRelationsFromDateFields
    distinctLabelHash = ActiveRecord::Base.connection.select_all('SELECT label FROM kor.entity_datings group by label having count(id) > 12')
    numberOfRows = distinctLabelHash.count
    index = 0
    while index < numberOfRows
      label = distinctLabelHash[index]["label"]
      
      @@lastFieldKindID += 1
      date = Kind.new
      date.id = @@lastFieldKindID
      date.name = label
  
      @@lastFieldRelationID += 1
      hasDate = Relation.new
      hasDate.id = @@lastFieldRelationID
      hasDate.name = "hat " + label
      hasDate.reverse_name = "ist " + label + " von"
      hasDate.actualRelations = Array.new
      
      label.gsub! /"/, '' #'"'s in Strings -> interrupt SQLQUERYSTRING!!!
      queryString = "SELECT * FROM kor.entity_datings join kor.entities on kor.entity_datings.entity_id = kor.entities.id where label like \"#{label}\" group by kor.entities.kind_id, kor.entity_datings.label"    
      kindsForLabelHashRows = ActiveRecord::Base.connection.select_all(queryString)

      for kindsForLabelHashRow in kindsForLabelHashRows
        for kind in @@kinds
          if kind.id ==kindsForLabelHashRow["kind_id"]
            actualRelation = ActualRelation.new
            actualRelation.relation = hasDate
            actualRelation.domain = kind
            actualRelation.range = date
            hasDate.actualRelations.push actualRelation
          end
        end 
      end
       
      @@kinds.push date
      @@relations.push hasDate      
      index += 1
    end 
  end
  
  private #TODOs
  def self.addAdditionalKindsAndRelationsFromDynamicFields
    
  end 
end