module KorCrmMapping::ShortestPathCalculator
  
  def self.shortestPathTest
    loadMappingObjects
    for crmClass in @@crmClasses
      if crmClass.uri.path.eql? '/120111/E21_Person'
        sourceClass = crmClass
      end
      if crmClass.uri.path.eql? '/120111/E24_Physical_Man-Made_Thing'
        targetClass = crmClass
      end
    end
    
    puts sourceClass.label
    puts targetClass.label
    
    sourcePropertiesWithDomain = getPropertiesOfClass sourceClass, @@crmProperties
    for sourcePropertyWithDomain in sourcePropertiesWithDomain
      domain = sourcePropertyWithDomain.range
      puts "ShortestPath via #{sourcePropertyWithDomain.label}"
      pathLength = bfs domain, targetClass, @@crmProperties
      puts pathLength
    end
    return # nothing, else memory allocation error!!!!!!!!!!!!!!!
  end
  
  def self.dijkstraTest
    loadMappingObjects
    
    relationToMapName = "hat geschaffen"
    for crmProperty in @@crmProperties
      crmProperty.setSimilarity relationToMapName
    end
    
    for crmClass in @@crmClasses
      if crmClass.uri.path.eql? '/120111/E21_Person'
        sourceClass = crmClass
      end
      if crmClass.uri.path.eql? '/120111/E24_Physical_Man-Made_Thing'
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

  def self.dijkstra crmProperties, sourceClass, targetClass #without specialisation!!!
    green = Array.new
    yellow= Array.new
    red = Array.new
    dist = Hash.new
    
    #initialization
    yellow.push sourceClass  
    dist[sourceClass] = 0
    
    #sonderfall shortest path to same node!!!
    
    while !yellow.empty?
         
      #select seen node with least distance to startNode
      nodeWithMinDistance = findNodeWithMinDist yellow, dist
      green.push nodeWithMinDistance
      yellow.delete nodeWithMinDistance
      
      if nodeWithMinDistance == targetClass
        break
      end

      propertiesOfClass = getPropertiesOfClass nodeWithMinDistance, crmProperties
      for propertyOfClass in propertiesOfClass
        puts propertyOfClass.label
        puts propertyOfClass.similarity
        if !(yellow.include? propertyOfClass.range or green.include? propertyOfClass.range) #node grey
          helpProperty = HelpProperty.new      
          helpProperty.label = propertyOfClass.label
          helpProperty.uri = propertyOfClass.uri
          helpProperty.domain = nodeWithMinDistance
          helpProperty.range = propertyOfClass.range
          red.push helpProperty
          
          yellow.push propertyOfClass.range
          dist[propertyOfClass.range] = dist[nodeWithMinDistance] + propertyOfClass.similarity
        else
          if yellow.include? propertyOfClass.range #node yellow
            if dist[propertyOfClass.range] > dist[nodeWithMinDistance] + propertyOfClass.similarity #never true since similarity always 1!!!
              helpProperty = HelpProperty.new      
              helpProperty.label = propertyOfClass.label
              helpProperty.uri = propertyOfClass.uri
              helpProperty.domain = nodeWithMinDistance
              helpProperty.range = propertyOfClass.range
              red.push helpProperty
              
              for property in red
                if property.range.eql? propertyOfClass.range
                  red.delete property
                end
              end   
                        
              dist[propertyOfClass.range] = dist[nodeWithMinDistance] + propertyOfClass.similarity            
            end
          else #node green
          end
        end
      end  
    end
    return red
  end
  
  def self.findNodeWithMinDist yellow, dist
    i = 0
    minDist = dist[yellow[i]]
    nodeWithMinDistance = yellow[i]
    while i < yellow.size - 1
      i += 1
       if dist[yellow[i]] < minDist
        minDist = dist[yellow[i]]
        nodeWithMinDistance = yellow[i]
      end
    end
    nodeWithMinDistance
  end
  
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
  
  def self.bfs sourceClass, targetClass, crmProperties
    #initialization
    pathLength = 0
    queue = Array.new
    visited = Array.new
    
    visited.push sourceClass
    
    level = 0
    numberOfNodesOnLevel = Hash.new 0
    queue.push sourceClass  
    numberOfNodesOnLevel[level] += 1
    
    numberOfDropsOnLevel= 0
    
    while !queue.empty?
      if numberOfDropsOnLevel == numberOfNodesOnLevel[level] #-> next level reached
        numberOfDropsOnLevel = 0
        level += 1
      end
      
      crmClass = queue.first
      queue = queue.drop(1)
      numberOfDropsOnLevel += 1
     
      if crmClass.isA? targetClass
        #shortestPath found!!!
        pathLength = level + 1
        break
      end 
  
      propertiesWithDomain = getPropertiesOfClassAndSubclasses crmClass, crmProperties
      for propertyWithDomain in propertiesWithDomain
        range = propertyWithDomain.range
        if !visited.include? range
          queue.push range
          numberOfNodesOnLevel[level + 1] += 1
          visited.push range
        end
      end
    end
    
    ## 0 -> infinite!
    return pathLength
  end
  
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
  
end