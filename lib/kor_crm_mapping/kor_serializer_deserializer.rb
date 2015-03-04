module KorCrmMapping::KorSerializerDeserializer
  
  private
  def self.serializeKindsInJason kinds
    kindsFile = File.new("korKinds", "w")
    numberOfKinds = kinds.size
    i = 0
    while i < numberOfKinds
      kindsFile.write kinds[i].to_json
      i += 1
      if i < numberOfKinds
        kindsFile.write "\n"
      end
    end
    kindsFile.close
  end
  
  private
  def self.serializeKindInJason kind 
    File.write(f = "korKinds", File.read(f).gsub(/^{"json_class":"Kind","data":{"id":#{kind.id},.*$/,kind.to_json))
  end
  
  private
  def self.serializeRelationsInJason relations
    relationsFile = File.new("korRelations", "w")
    numberOfRelations = relations.size
    i = 0
    while i < numberOfRelations
      relationsFile.write relations[i].to_json
      i += 1
      if i < numberOfRelations
        relationsFile.write "\n"
      end
    end
    relationsFile.close 
  end
  
  private
  def self.serializeRelationInJason relation 
    File.write(f = "korRelations", File.read(f).gsub(/^{"json_class":"Relation","data":{"id":#{relation.id},.*$/,relation.to_json))
  end
  
  private
  def self.deserializeKindsInJason
    kinds = Array.new
    kindsFile = File.open("korKinds")
    
    until kindsFile.eof()
      serializedKind = kindsFile.readline()
      kinds.push Kind.json_create serializedKind
    end

    kindsFile.close 
    kinds     
  end
  
  private
  def self.deserializeRelationsInJason
    relations = Array.new
    relationsFile = File.open("korRelations")
    
    until relationsFile.eof()
      serializedRelation = relationsFile.readline()
      relations.push Relation.json_create serializedRelation
    end

    relationsFile.close 
    relations      
  end
end