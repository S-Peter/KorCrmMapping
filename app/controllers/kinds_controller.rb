class KindsController < ApplicationController
  
  def index
    @kinds = KorCrmMapping::KorSerializerDeserializer.deserializeKindsInJason
    crmClasses = KorCrmMapping::CrmSerializerDeserializer.deserializeClassesInJason
    for kind in @kinds
      kind.reestablishLinks crmClasses
    end
  end
  
  def edit   
    kindId = params[:id]
    @kind = findKind kindId    
    @crmClasses = KorCrmMapping::CrmSerializerDeserializer.deserializeClassesInJason
  end
  
  def update
    korKindId = params[:id]
    @kind = findKind korKindId   
    crmClassNumber = params[:crmc]
    @crmClass = findCRMClass crmClassNumber
    @kind.crmClass = @crmClass
    KorCrmMapping::KorSerializerDeserializer.serializeKindInJason @kind
    redirect_to kinds_path
  end
  
  private
  def findKind kindId
    kinds = KorCrmMapping::KorSerializerDeserializer.deserializeKindsInJason
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
  
  private
  def findCRMClass crmClassNumber
    crmClasses = KorCrmMapping::CrmSerializerDeserializer.deserializeClassesInJason
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
  
end
