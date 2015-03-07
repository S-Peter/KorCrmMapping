module KorCrmMapping::ShortestPathCalculator
  
  def self.calculateShortestPath (actualRelationship, crmProperties)
    #innerNodes most specific for which path shortest
    
  end
  
  def self.shTest
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
    #bfs @@crmProperties, sourceClass, targetClass
    bfs2 sourceClass, targetClass
    return # nothing, else memory allocation error!!!!!!!!!!!!!!!
  end
  
  def self.bfs (crmProperties, sourceClass, targetClass)
    @@crmProperties = crmProperties
    @@targetClass = targetClass
    
    visited= Array.new
    visited.push sourceClass
    
    @@i=0
    @@pathHash = Hash.new Array.new
    
    pathArray = Array.new
    leavingProperties= getLeavingProperties sourceClass
    calculatePathToTargetForPropertiesWithDomainClass leavingProperties, pathArray

    puts @@pathHash.inspect

  end
  
  private #Tiefendurchlauf!!!
  def self.calculatePathToTargetForPropertiesWithDomainClass (propertiesWithDomainClass, startPathArray)
    puts @@pathHash.size
    @@i+=1
    for propertyWithDomainClass in propertiesWithDomainClass  
      pathArray = startPathArray.dup #shallow copy -> only array copied, not elements of array
      pathArray.push propertyWithDomainClass
      if @@targetClass.isA? propertyWithDomainClass.range #-> found, exit condition
        puts "--------------------yes----------------------"
        pathArray.push propertyWithDomainClass
        @@pathHash[@@i] = pathArray
        break #shortest path from sourceClass to targetClass found, eventuelle mehrere properties mit shortest path!!!
      else 
        #leavingProperties = getLeavingProperties propertyWithDomainClass.range
        #calculatePathToTargetForPropertiesWithDomainClass leavingProperties, pathArray
      end
    end
  end
  
  private
  def self.getLeavingProperties (crmClass) #should return all properties of crmClass or its subClasses; class specification of inner node possible!!!
    crmClassSubAndSuperClasses = Array.new
    crmClassSubAndSuperClasses.push crmClass
    crmClassSubAndSuperClasses.concat crmClass.getDirectOrIndirectSubClasses
    crmClassSubAndSuperClasses.concat crmClass.getDirectOrIndirectSuperClasses
    propertiesWithDomainClass = Array.new
    for crmProperty in @@crmProperties
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
  
  def self.bfs2 (sourceClass, targetClass)
    sourcePropertiesWithDomain = getLeavingProperties sourceClass
    for sourcePropertyWithDomain in sourcePropertiesWithDomain
      domain = sourcePropertyWithDomain.range
      puts "ShortestPath via #{sourcePropertyWithDomain.label}"
      pathLength = realBfs domain, targetClass
      puts pathLength
    end
    
  end
  
  def self.realBfs sourceClass, targetClass
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
        #puts "Path Length: #{level + 1}"
        break
      end 
  
      propertiesWithDomain = getLeavingProperties crmClass
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
  
end