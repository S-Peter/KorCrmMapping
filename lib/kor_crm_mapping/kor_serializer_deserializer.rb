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
  def self.deserializeKindsInJason
    kinds = Array.new
    kindsFile = File.open("korKinds")
    
    until kindsFile.eof()
      serializedKind = kindsFile.readline()
      puts serializedKind
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
      puts serializedRelation
      relations.push Relation.json_create serializedRelation
    end

    relationsFile.close 
    relations      
  end
end