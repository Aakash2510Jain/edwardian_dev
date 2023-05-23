@isTest
public class TestGroupSeriesCSVFileController {
    
    static testmethod void groupSeriesTestCSVFormat(){
        
        GroupSeriesCSVFileController.groupSeriesCSVFormat();
    }
    
    public static testmethod void testExtendedException() {
        try {
            Integer i=0;
            // Your code here
            if (i < 5) throw new CustomException('This is bad');
        } catch (CustomException e) {  
            
            System.debug(e.getMessage());
        }  
    }
    
}