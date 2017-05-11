public with sharing class ExternalLead_FillDomain implements Triggers.Handler {
	
	public void Handle() {

		for (ExternalLead__c forExternalLead : (List<ExternalLead__c>) trigger.new) {
			
			if (forExternalLead.CompanyWebsite__c != null && forExternalLead.CompanyWebsite__c != '') forExternalLead.Domain__c = ExternalLead_Helper.getDomainFromUrl(forExternalLead.CompanyWebsite__c);
		}
	}
}