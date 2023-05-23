public class CSVFileUploaderController {
    
    @AuraEnabled    
    public static void processData(String fileData,String sobjectName,List<String> fields, String recordId){
        
        map<String,String> apiNameByLabelName 					= new map<String,String>();
        Map<String, Property_Standard_Price__c> standPriceMap 	= new Map<String, Property_Standard_Price__c>();
        List<Property_Standard_Price__c> standPriceList 		= new List<Property_Standard_Price__c>();
        
        standPriceList = [Select Id, Property__c, Standard_Price_For_Double_Twin_Double__c, Standard_Price_For_Double_Twin_Single__c,
                          Standard_Price_For_Triple_Room_2_Adult__c, Standard_Price_For_Triple_Room_3_Adults__c 
                          from Property_Standard_Price__c where Opportunity__c =: recordId];
        
        for(Property_Standard_Price__c stanPriceObj : standPriceList) {
            standPriceMap.put(stanPriceObj.Property__c, stanPriceObj);
        }
        
        List<Group_Series_Rates_Mapping__mdt> gsrCSVFileFormatList = [SELECT Group_Series_Field_API_Name__c,Id,Label,Sequence__c FROM Group_Series_Rates_Mapping__mdt];
        
        for(Group_Series_Rates_Mapping__mdt gsrm : gsrCSVFileFormatList) {
            apiNameByLabelName.put(gsrm.Label,gsrm.Group_Series_Field_API_Name__c);
        }       
        
        List<sObject> recordList = new List<sObject>();
        Schema.SObjectType targetType = Schema.getGlobalDescribe().get(sobjectName);
        
        try{
            if(fileData!=null) { 
                String[] fileLines = new String[]{};
                    fileLines = fileData.split('\n');
                //for content
                
                for (Integer i=1,j=fileLines.size();i<j;i++){
                    
                    String[] inputvalues = new String[]{};
                        inputvalues = fileLines[i].split(',');
                    
                    sObject obj = targetType.newSObject();
                    integer rowsize=inputvalues.size(); 
                    for(integer l=0;l<rowsize;l++){      
                        if(String.isNotBlank(inputvalues[l])) {
                            String value= inputvalues[l].length()>255 ? inputvalues[l].substring(0,254) : inputvalues[l];
                            
                            if(fields.get(l) == 'Date From' || fields.get(l) == 'Date To'){
                                if(value != null){
                                    obj.put(apiNameByLabelName.get(fields.get(l)),date.valueOf(value));     
                                }
                                
                            }
                            else if(fields.get(l) == 'Is Breakfast Included?'){
                                obj.put(apiNameByLabelName.get(fields.get(l)),boolean.valueOf(value));
                            }
                            else if(fields.get(l) == 'Overwrite Standard Price'){
                                obj.put(apiNameByLabelName.get(fields.get(l)),boolean.valueOf(value));
                            }
                            else if(fields.get(l) == 'Double/Twin Single Occupancy' || fields.get(l) == 'Double/Twin Double Occupancy' || 
                                    fields.get(l) == 'Triple Room 2 Adults + 1 Child(0-12 yrs)' ||  fields.get(l) == 'Triple Room 3 Adults'){
                                        value = value.replaceAll('[^a-zA-Z0-9\\s+]', '');
                                        value = value.replaceAll('\r', '');
                                        obj.put(apiNameByLabelName.get(fields.get(l)),getDecimalValue(value));
                                    }
                            else if(fields.get(l) == 'ROOMS'){
                                try{
                                    obj.put(apiNameByLabelName.get(fields.get(l)),value);  
                                }catch(Exception e){
                                    system.debug('exception @ Line'+e.getMessage() + 'cause' + e.getCause());
                                    throw new CustomException('Invalid value for Rooms.'); 
                                }
                            }else if(fields.get(l) == 'Hotel Name'){
                                try{
                                    system.debug('fields.get(l))'+apiNameByLabelName.get(fields.get(l))+'value'+value);
                                    obj.put(apiNameByLabelName.get(fields.get(l)),value);  
                                }catch(Exception e){
                                    system.debug('exception @ Line'+e.getMessage() + 'cause' + e.getCause());
                                    throw new CustomException('Invalid value for Hotel Name.'); 
                                }
                            }
                            else if(fields.get(l) == 'Room Type'){
                                try{
                                    system.debug('fields.get(l))'+apiNameByLabelName.get(fields.get(l))+'value'+value);
                                    obj.put(apiNameByLabelName.get(fields.get(l)),value);  
                                }catch(Exception e){
                                    system.debug('exception @ Line'+e.getMessage() + 'cause' + e.getCause());
                                    throw new CustomException('Invalid value for Room Type.'); 
                                }
                            }
                            else{                                
                                obj.put(apiNameByLabelName.get(fields.get(l)),value);    
                            }                                                            
                        }
                        else{
                            if( (fields.get(l) == 'Double/Twin Single Occupancy') || (fields.get(l) == 'Double/Twin Double Occupancy') || (fields.get(l) == 'Triple Room 2 Adults + 1 Child(0-12 yrs)') || (fields.get(l) == 'Triple Room 3 Adults' )){
                                obj.put( apiNameByLabelName.get(fields.get(l)),null);    
                            }
                            else{
                                throw new CustomException(fields.get(l) + ' is mandatory.'); 
                            } 
                        }
                    }
                     system.debug('standPriceMap' + standPriceMap);
                    
                    if(obj.get('Overwrite_Standard_Price__c') == true && 
                       (obj.get('Double_Twin_Single_Occupancy__c') == null || obj.get('Double_Twin_Double_Occupancy__c') == null || 
                        obj.get('Triple_Room_2_Adults_1_Child__c') == null || obj.get('Triple_Room_3_Adults__c') == null))  {
                        throw new CustomException('Please fill all Prices for Overwrite Standard Price = TRUE'); 
                    }
                    if(obj.get('Overwrite_Standard_Price__c') != true) {
                        system.debug('standPriceMap' + standPriceMap);
                        system.debug('obj.get' + obj.get('Hotel__c'));
                        system.debug('value of'+ standPriceMap.containsKey(String.valueOf(obj.get('Hotel__c'))));
                        if(standPriceMap.containsKey(String.valueOf(obj.get('Hotel__c'))) == true){
                            if(standPriceMap.containsKey(String.valueOf(obj.get('Hotel__c'))) && standPriceMap.get(String.valueOf(obj.get('Hotel__c'))).Standard_Price_For_Double_Twin_Double__c != null)
                        obj.put('Double_Twin_Double_Occupancy__c', standPriceMap.get(String.valueOf(obj.get('Hotel__c'))).Standard_Price_For_Double_Twin_Double__c);
                        if(standPriceMap.containsKey(String.valueOf(obj.get('Hotel__c'))) && standPriceMap.get(String.valueOf(obj.get('Hotel__c'))).Standard_Price_For_Double_Twin_Single__c != null)
                            obj.put('Double_Twin_Single_Occupancy__c', standPriceMap.get(String.valueOf(obj.get('Hotel__c'))).Standard_Price_For_Double_Twin_Single__c);
                        if(standPriceMap.containsKey(String.valueOf(obj.get('Hotel__c'))) && standPriceMap.get(String.valueOf(obj.get('Hotel__c'))).Standard_Price_For_Triple_Room_2_Adult__c != null)
                            obj.put('Triple_Room_2_Adults_1_Child__c', standPriceMap.get(String.valueOf(obj.get('Hotel__c'))).Standard_Price_For_Triple_Room_2_Adult__c);
                        if(standPriceMap.containsKey(String.valueOf(obj.get('Hotel__c'))) && standPriceMap.get(String.valueOf(obj.get('Hotel__c'))).Standard_Price_For_Triple_Room_3_Adults__c != null)
                            obj.put('Triple_Room_3_Adults__c', standPriceMap.get(String.valueOf(obj.get('Hotel__c'))).Standard_Price_For_Triple_Room_3_Adults__c);   
                        }
                        else{
                            throw new CustomException('Standard Price value not available for' + ' ' + String.valueOf(obj.get('Hotel__c')));
                        }
                                             
                    }
                        recordList.add(obj);
                }
            }
            if (recordList.size() > 0) { 
                for(sObject obj : recordList){
                    obj.put('Opportunity__c', recordId);
                }               
                insert recordList;
            }
        }
        catch(Exception e){
            System.debug('exception'+e +'@'+e.getLineNumber());   
            if(e.getMessage().startsWith('Invalid date')) {
                throw new CustomException('Invalid Date Format(req. format : YYYY-MM-DD)');
            }else if( e.getMessage().contains('INVALID_OR_NULL_FOR_RESTRICTED_PICKLIST')){
                throw new CustomException('Invalid Hotel Selection');
            }
            else{
                system.debug('Exception @ '+e.getLineNumber());
                throw new CustomException(e.getMessage());
            }
        }
        
    }
    
    
    public static Decimal getDecimalValue(String str){
        Decimal ans = null;
        try{
            ans = Decimal.valueOf(str);
        }catch(TypeException ex){
            throw new CustomException('Invalid value for Rooms.'); 
        }
        return ans;
    }
    
}