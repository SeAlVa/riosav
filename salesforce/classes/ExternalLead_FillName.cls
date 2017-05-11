public without sharing class ExternalLead_FillName implements Triggers.Handler {
    public void Handle(){
        for(ExternalLead__c forExternalLead : (List<ExternalLead__c>)trigger.new) {
            forExternalLead.Name = (forExternalLead.FirstName__c == null?'':forExternalLead.FirstName__c) + ' ' + (forExternalLead.LastName__c == null?'':forExternalLead.LastName__c);
        }
    }
}