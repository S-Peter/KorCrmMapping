module KorCrmMatching::ShortestPathCalculator
  
  class HelpProperty
    attr_accessor :actualDomain, :actualRange, :property, :end
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
end