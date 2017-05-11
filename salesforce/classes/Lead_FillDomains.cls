public with sharing class Lead_FillDomains implements Triggers.Handler {
	
	public void Handle() {

		for (Lead forLead : (List<Lead>) trigger.new) {
			
			if (forLead.Website != null && forLead.Website != '') forLead.WebsiteDomain__c = ExternalLead_Helper.getDomainFromUrl(forLead.Website);
			if (forLead.Email != null && forLead.Email != '') forLead.EmailDomain__c = ExternalLead_Helper.getDomainFromEmail(forLead.Email);
		}
	}
}