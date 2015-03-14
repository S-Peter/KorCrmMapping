module KorCrmMapping::ShortestPathCalculator
  
  def self.helpPropertyTest
    loadMappingObjects
    
    sourceClass = nil
    for crmClass in @@crmClasses
      if crmClass.uri.path.eql? '/120111/E39_Actor'
        sourceClass = crmClass
        break
      end
    end
    
    helpProperties = getPropertiesOfClassAndSubclasses2 crmClass, @@crmProperties
    puts helpProperties.size
    for hp in helpProperties
      puts "Property: #{hp.label}, Domain: #{hp.domain.label}, Range: #{hp.range.label}"
      if crmClass.isA? hp.domain
        puts "#{crmClass.label} is domain of Property"
      else 
        puts puts "Domain of Property is Subclass of #{crmClass.label}"
      end
    end
    return
  end
  
  def self.dijkstraTest
    loadMappingObjects
    
    relationToMapName = "Herausgeber/in von"
    for crmProperty in @@crmProperties
      crmProperty.setSimilarity relationToMapName
    end
    
    for crmClass in @@crmClasses
      if crmClass.uri.path.eql? '/120111/E40_Legal_Body'
        sourceClass = crmClass
      end
      if crmClass.uri.path.eql? '/120111/E73_Information_Object'
        targetClass = crmClass
      end
    end
    
    puts relationToMapName
    puts sourceClass.label
    puts targetClass.label
    
    puts "---------------------Dijkstra------------------"
    shortestPathProperties = dijkstra @@crmProperties, sourceClass, targetClass
    dFile = File.new("dijkstra", "w")
    for property in shortestPathProperties #helpProperties!!!
      dFile.write "Property: Path: #{property.uri.path}, Label: #{property.label}, Domain: #{property.domain.label}, Range: #{property.range.label}"
      dFile.write "\n"
    end
    dFile.close
    
    shortestPath = calculateShortestPathFromTargetToSource shortestPathProperties, sourceClass, targetClass
    shortestPath.reverse!
    puts "++++++++++++++++++++++++++++++++++++++++++++++"
    puts "ShortestPath:"
    for element in shortestPath
      puts element.label
    end

    return # nothing, else memory allocation error!!!!!!!!!!!!!!!
  end

  def self.dijkstra crmProperties, startNode, targetNode
    visitedNodes = Array.new
    spottedNodes = Array.new
    shortestEdgesToNodes = Array.new
    distances = Hash.new
    
    #initialization
    spottedNodes.push startNode  
    distances[startNode] = 0
    
    #sonderfall shortest path to same node!!! TODO
    
    while !spottedNodes.empty?
         
      #select spotted node with least distance to startNode
      nodeWithMinDistance = findNodeWithMinDist spottedNodes, distances
      puts nodeWithMinDistance.label
      visitedNodes.push nodeWithMinDistance
      spottedNodes.delete nodeWithMinDistance
      
      if targetNode.isA? nodeWithMinDistance
        puts "Target Node #{nodeWithMinDistance.label} reached!"
        break
      end

      helpPropertiesOfClass = getPropertiesOfClassAndSubclasses nodeWithMinDistance, crmProperties
      for helpPropertyOfClass in helpPropertiesOfClass
        if !(spottedNodes.include? helpPropertyOfClass.range or visitedNodes.include? helpPropertyOfClass.range)
          shortestEdgesToNodes.push helpPropertyOfClass
          
          spottedNodes.push helpPropertyOfClass.range
          distances[helpPropertyOfClass.range] = distances[nodeWithMinDistance] + helpPropertyOfClass.similarity
        else
          if spottedNodes.include? helpPropertyOfClass.range
            if distances[helpPropertyOfClass.range] > distances[nodeWithMinDistance] + helpPropertyOfClass.similarity
                         
              for property in shortestEdgesToNodes
                if property.range.eql? helpPropertyOfClass.range
                  shortestEdgesToNodes.delete property
                end
              end   
              
              shortestEdgesToNodes.push helpPropertyOfClass                        
              distances[helpPropertyOfClass.range] = distances[nodeWithMinDistance] + helpPropertyOfClass.similarity            
            end
          end
        end
      end  
    end
    return shortestEdgesToNodes #HelpProperties
  end
  
  def self.findNodeWithMinDist spottedNodes, distances
    i = 0
    minDist = distances[spottedNodes[i]]
    nodeWithMinDistance = spottedNodes[i]
    while i < spottedNodes.size - 1
      i += 1
       if distances[spottedNodes[i]] < minDist
        minDist = distances[spottedNodes[i]]
        nodeWithMinDistance = spottedNodes[i]
      end
    end
    nodeWithMinDistance
  end

=begin  
  private
  def self.getPropertiesOfClass (crmClass, crmProperties) #returns all properties of crmClass and those inherited from its superclasses
    crmClassSubAndSuperClasses = Array.new
    crmClassSubAndSuperClasses.push crmClass
    crmClassSubAndSuperClasses.concat crmClass.getDirectOrIndirectSuperClasses
    propertiesWithDomainClass = Array.new
    for crmProperty in crmProperties
      for crmClass in crmClassSubAndSuperClasses
        if crmClass.isA? crmProperty.domain
          if !propertiesWithDomainClass.include? crmProperty
            propertiesWithDomainClass.push crmProperty
          end
        end
      end
    end
    propertiesWithDomainClass
  end
=end
=begin  
  private
  def self.getPropertiesOfClassAndSubclasses (crmClass, crmProperties) #returns all properties of crmClass and those inherited from its superclasses + those of its subClasses since class specification of inner node is possible!!!
    crmClassSubAndSuperClasses = Array.new
    crmClassSubAndSuperClasses.push crmClass
    crmClassSubAndSuperClasses.concat crmClass.getDirectOrIndirectSubClasses
    crmClassSubAndSuperClasses.concat crmClass.getDirectOrIndirectSuperClasses
    propertiesWithDomainClass = Array.new
    for crmProperty in crmProperties
      for crmClass in crmClassSubAndSuperClasses
        if crmClass.isA? crmProperty.domain
          if !propertiesWithDomainClass.include? crmProperty
            propertiesWithDomainClass.push crmProperty
          end
        end
      end
    end
    propertiesWithDomainClass
  end
=end
  
  private
  def self.getPropertiesOfClassAndSubclasses (crmClass, crmProperties) #returns all properties of crmClass and those inherited from its superclasses + those of its subClasses since class specification of inner node is possible!!!
    propertiesWithClassAsDomainClass = Array.new
    
    crmClassSubAndSuperClasses = Array.new
    crmClassSubAndSuperClasses.push crmClass
    crmClassSubAndSuperClasses.concat crmClass.getDirectOrIndirectSubClasses
    crmClassSubAndSuperClasses.concat crmClass.getDirectOrIndirectSuperClasses
    
    for crmClass in crmClassSubAndSuperClasses
      for crmProperty in crmProperties
        if crmClass == crmProperty.domain
          helpProperty = HelpProperty.new      
          helpProperty.label = crmProperty.label
          helpProperty.uri = crmProperty.uri
          helpProperty.similarity = crmProperty.similarity
          helpProperty.domain = crmProperty.domain
          helpProperty.range = crmProperty.range
          propertiesWithClassAsDomainClass.push helpProperty
        end
      end
    end
    
    propertiesWithClassAsDomainClass
  end
  
  def self.calculateShortestPathFromTargetToSource shortestPathProperties, sourceClass, targetClass #HelpProperties
    shortestPathFromTargetToSource = Array.new
    if sourceClass != targetClass
      for shortestPathProperty in shortestPathProperties
        if shortestPathProperty.range == targetClass
          shortestPathFromTargetToSource.push targetClass
          shortestPathFromTargetToSource.push shortestPathProperty
          shortestPathFromTargetToSource.concat calculateShortestPathFromTargetToSource shortestPathProperties, sourceClass, shortestPathProperty.domain
        end
      end
    else
      shortestPathFromTargetToSource.push sourceClass
    end
    return shortestPathFromTargetToSource
  end  
  
  private
  def self.loadMappingObjects
    @@crmClasses = KorCrmMapping::CrmSerializerDeserializer.deserializeClassesInJason
    for crmClass in @@crmClasses
      crmClass.reestablishLinks @@crmClasses
    end
    @@crmProperties = KorCrmMapping::CrmSerializerDeserializer.deserializePropertiesInJason
    for crmProperty in @@crmProperties
      crmProperty.reestablishLinks @@crmProperties, @@crmClasses
    end
    @@kinds = KorCrmMapping::KorSerializerDeserializer.deserializeKindsInJason
    for kind in @@kinds
      kind.reestablishLinks @@crmClasses
    end
    @@relations = KorCrmMapping::KorSerializerDeserializer.deserializeRelationsInJason
    for relation in @@relations
      relation.reestablishLinks @@kinds, @@crmClasses, @@crmProperties
    end
  end
  
=begin  
    def self.findPathFromTargetToSource (properties, source, target)
    propertiesToNode = Array.new
    for property in properties
      if property.range == target
        propertiesToNode.push property
      end
    end
    puts "Number of properties to node(must be 1!!!): #{propertiesToNode.size}"
    puts propertiesToNode.last.domain.label
    puts source.label
    if propertiesToNode.last.domain != source
      puts "if"
      propertiesToNode.concat findPathFromTargetToSource properties, source, propertiesToNode.last.domain
    end  
    return propertiesToNode
  end
=end  
end