public with sharing class SearchLeadsController {

    public ExternalLead__c filter {get{if(filter == null) filter = new ExternalLead__c(); return filter;} set;}
    
    public List<ExternalLead__c> getLeads(){
        List<String> whereConditions = new List<String>();
        
        if (filter.Source__c != null && filter.Source__c != '') {
            whereConditions.add('Source__c = \'' + filter.Source__c + '\'');
        }
        
        if (filter.Industry__c != null && filter.Industry__c != '') {
            whereConditions.add('Industry__c LIKE \'' + filter.Industry__c + '%\'');
        }
        
        if (filter.FirstName__c != null && filter.FirstName__c != '') {
            whereConditions.add('FirstName__c LIKE \'' + filter.FirstName__c.replace('\'','\\\'') + '%\'');
        }
        
        if (filter.LastName__c != null && filter.LastName__c != '') {
            whereConditions.add('LastName__c LIKE \'' + filter.LastName__c.replace('\'','\\\'') + '%\'');
        }
        
        return database.query(
            String.format(
                'SELECT Name, Company__c, Industry__c, Source__c, CompanySize__c FROM ExternalLead__c {0}',
                new List<String>{
                    whereConditions.size() > 0?'WHERE ' + String.join(whereConditions,' AND '):''
                }
            )
        );
    }
}