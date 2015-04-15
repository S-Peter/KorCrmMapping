module KorCrmMatching::ShortestPathCalculator
  
  class HelpProperty
    attr_accessor :actualDomain, :actualRange, :property, :end
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
    inheritanceFreePropertyGraph = deriveInheritanceFreePropertyGraph @@crmProperties
    puts inheritanceFreePropertyGraph.size
    shortestPathProperties = dijkstra inheritanceFreePropertyGraph, sourceClass, targetClass
    
    for shortestPathProperty in shortestPathProperties
      if shortestPathProperty.end == true
        targetClass = shortestPathProperty.actualDomain
        break
      end
    end
    shortestPathProperties.delete shortestPathProperty
    
    dFile = File.new("dijkstra", "w")
    for property in shortestPathProperties #helpProperties!!!
      dFile.write "Property: Path: #{property.property.uri.path}, Label: #{property.property.label}, Domain: #{property.actualDomain.label}, Range: #{property.actualRange.label}"
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

    return
  end
  
  def self.deriveInheritanceFreePropertyGraph crmProperties
    inheritanceFreeCrmProperties = Array.new
    
    for crmProperty in crmProperties
      #get domain and subclasses
      domainClasses = Array.new
      domainClasses.push crmProperty.domain
      domainClasses.concat crmProperty.domain.getDirectOrIndirectSubClasses
      
      for domainClass in domainClasses
        #get range and subclasses
        rangeClasses = Array.new
        rangeClasses.push crmProperty.range
        rangeClasses.concat crmProperty.range.getDirectOrIndirectSubClasses
        for rangeClass in rangeClasses
          inheritanceFreeCrmProperty = HelpProperty.new
          inheritanceFreeCrmProperty.property = crmProperty
          inheritanceFreeCrmProperty.actualDomain = domainClass
          inheritanceFreeCrmProperty.actualRange = rangeClass
          inheritanceFreeCrmProperties.push inheritanceFreeCrmProperty
        end
      end
    end
    
    return inheritanceFreeCrmProperties
  end
  
  def self.dijkstra inheritanceFreeCrmProperties, startClass, targetClass
    visitedNodes = Array.new
    discoveredNodes = Array.new
    shortestEdgesToNodes = Array.new
    distances = Hash.new
    
    if !(startClass.uri.eql? targetClass.uri) #else special case: shortest path to same node!!! TODO
      #initialization
      discoveredNodes.push startClass  
      distances[startClass] = 0
      
      while !discoveredNodes.empty? 
        #select discovered node with least distance to startNode
        nodeWithMinDistance = findNodeWithMinDist discoveredNodes, distances
        visitedNodes.push nodeWithMinDistance
        discoveredNodes.delete nodeWithMinDistance
        
        if targetClass.isA? nodeWithMinDistance
          endProperty = HelpProperty.new
          endProperty.actualDomain = nodeWithMinDistance
          endProperty.actualRange = nodeWithMinDistance
          endProperty.end = true
          shortestEdgesToNodes.push endProperty
          break
        end
        
        leavingProperties = Array.new
        for property in inheritanceFreeCrmProperties
          if property.actualDomain.uri.eql? nodeWithMinDistance.uri
            leavingProperties.push property
          end
        end
        
        for leavingProperty in leavingProperties
          if !((discoveredNodes.include? leavingProperty.actualRange) or (visitedNodes.include? leavingProperty.actualRange))
            shortestEdgesToNodes.push leavingProperty
            
            discoveredNodes.push leavingProperty.actualRange
            distances[leavingProperty.actualRange] = distances[nodeWithMinDistance] + leavingProperty.property.similarity
          else
            if discoveredNodes.include? leavingProperty.actualRange
              if distances[leavingProperty.actualRange] > distances[nodeWithMinDistance] + leavingProperty.property.similarity
                
                for property in shortestEdgesToNodes
                  if property.actualRange.eql? leavingProperty.actualRange
                    shortestEdgesToNodes.delete property
                  end
                end   
                
                shortestEdgesToNodes.push leavingProperty                        
                distances[leavingProperty.actualRange] = distances[nodeWithMinDistance] + leavingProperty.property.similarity
              end
            end
          end  
        end
      end
    end
    
    return shortestEdgesToNodes #HelpProperties
  end
  
  def self.findNodeWithMinDist discoveredNodes, distances
    i = 0
    minDist = distances[discoveredNodes[i]]
    nodeWithMinDistance = discoveredNodes[i]
    while i < discoveredNodes.size - 1
      i += 1
       if distances[discoveredNodes[i]] < minDist
        minDist = distances[discoveredNodes[i]]
        nodeWithMinDistance = discoveredNodes[i]
      end
    end
    nodeWithMinDistance
  end

  def self.calculateShortestPathFromTargetToSource shortestPathProperties, sourceClass, targetClass #HelpProperties
    shortestPathFromTargetToSource = Array.new
    if !sourceClass.uri.eql? targetClass.uri

      for shortestPathProperty in shortestPathProperties
        if shortestPathProperty.actualRange.uri.eql? targetClass.uri
          shortestPathFromTargetToSource.push targetClass
          shortestPathFromTargetToSource.push shortestPathProperty.property
          shortestPathFromTargetToSource.concat calculateShortestPathFromTargetToSource shortestPathProperties, sourceClass, shortestPathProperty.actualDomain
        end
      end
    else
      shortestPathFromTargetToSource.push sourceClass
    end
    return shortestPathFromTargetToSource
  end  
  
  private
  def self.loadMappingObjects
    @@crmClasses = KorCrmSerializingDeserializing::CrmSerializerDeserializer.deserializeClassesInJason
    for crmClass in @@crmClasses
      crmClass.reestablishLinks @@crmClasses
    end
    @@crmProperties = KorCrmSerializingDeserializing::CrmSerializerDeserializer.deserializePropertiesInJason
    for crmProperty in @@crmProperties
      crmProperty.reestablishLinks @@crmProperties, @@crmClasses
    end
    @@kinds = KorCrmSerializingDeserializing::KorSerializerDeserializer.deserializeKindsInJason
    for kind in @@kinds
      kind.reestablishLinks @@crmClasses
    end
    @@relations = KorCrmSerializingDeserializing::KorSerializerDeserializer.deserializeRelationsInJason
    for relation in @@relations
      relation.reestablishLinks @@kinds, @@crmClasses, @@crmProperties
    end
  end 
end