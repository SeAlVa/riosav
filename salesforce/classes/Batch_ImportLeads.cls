public class Batch_ImportLeads implements Schedulable {
    public static String CRON_EXP = '0 0 0 * * ? *';
    
    private static final Map<String,String> fieldMapping = new Map<String,String>{
        'uuid'              => 'UUID__c',
        'firstname'         => 'FirstName__c',
        'lastname'          => 'LastName__c',
        'company'           => 'Company__c',
        'company_website'   => 'CompanyWebsite__c',
        'company_size'      => 'CompanySize__c',
        'source'            => 'Source__c',
        'industry'          => 'Industry__c'
    };
    
    
    
    public void execute(SchedulableContext ctx) {

        try {
            Map<String,Set<String>> domainsUsed = new Map<String,Set<String>>();
            List<Object> leads = (List<Object>)JSON.deserializeUntyped(Util.PostMan.doGet('callout:ExternalLeads?limit=10000',null).getBody()); // worse case scenario, 10'000 rows
            List<ExternalLead__c> externalLeadCandidates = new List<ExternalLead__c>();


            Set<String> uuids = extractUUID(leads);
            Set<String> existingUuids = new Set<String>();

            // Fetch known uuids from DB
            for (ExternalLead__c forExternalLead : [SELECT UUID__c FROM ExternalLead__c WHERE UUID__c IN :uuids]) {
                existingUuids.add(forExternalLead.UUID__c);
            }

            for (Object forExternalLeadObject : leads) {
                Map<String,Object> forExternalLead = (Map<String,Object>)forExternalLeadObject;
                
                // if its new, we have to consider it
                if (!existingUuids.contains(String.valueOf(forExternalLead.get('uuid')))){
                    ExternalLead__c externalLeadCandidate = new ExternalLead__c();
                    
                    for (String forField : forExternalLead.keySet()){
                        
                        if (fieldMapping.get(forField) != null) {
                            externalLeadCandidate.put(fieldMapping.get(forField),forExternalLead.get(forField));
                        }
                    }
                    
                    if (externalLeadCandidate.CompanyWebsite__c != null && externalLeadCandidate.CompanyWebsite__c != '') {
                        externalLeadCandidate.Domain__c = ExternalLead_Helper.getDomainFromUrl(externalLeadCandidate.CompanyWebsite__c);
                        domainsUsed.put(externalLeadCandidate.Domain__c, new Set<String>());
                    }

                    // to review after
                    externalLeadCandidates.add(externalLeadCandidate);
                }
            }
            System.debug(domainsUsed);
            // Now we have all the candidates as ExternalLead__c

            // lets find out which the ones have domains used
            for (Lead forLead : [SELECT EmailDomain__c, WebsiteDomain__c FROM Lead WHERE EmailDomain__c IN :domainsUsed.keySet() OR WebsiteDomain__c IN :domainsUsed.keySet()]) {
                if (forLead.EmailDomain__c != null && forLead.EmailDomain__c != '' && domainsUsed.containsKey(forLead.EmailDomain__c)) {
                    domainsUsed.get(forLead.EmailDomain__c).add(forLead.Id);
                }

                if (forLead.WebsiteDomain__c != null && forLead.WebsiteDomain__c != '' && domainsUsed.containsKey(forLead.WebsiteDomain__c)) {
                    domainsUsed.get(forLead.WebsiteDomain__c).add(forLead.Id);
                }
            }

            for (ExternalLead__c forExternalLead : [SELECT Domain__c, UUID__c FROM ExternalLead__c WHERE Domain__c IN :domainsUsed.keySet()]) {
                if (forExternalLead.Domain__c != null && forExternalLead.Domain__c != '' && domainsUsed.containsKey(forExternalLead.Domain__c)) {
                    domainsUsed.get(forExternalLead.Domain__c).add(forExternalLead.Id);
                }
            }

            // Now that we have mapped all the domains used is time to check the candidates.


            Util.EmailLog.init(new List<String>{'UUID','First Name','Last Name','Website','Message'});

            Map<Integer, Integer> dmlToCandidateMap = new Map<Integer,Integer>(); // Maps the row of ones that are going to get inserted to the candidate row

            Integer candidateIndex = 0, dmlIndex = 0;
            List<ExternalLead__c> externalLeadsToInsert = new List<ExternalLead__c>();

            for (ExternalLead__c forExternalLead : externalLeadCandidates) {
                Util.EmailLog.set('UUID', forExternalLead.UUID__c);
                Util.EmailLog.set('First Name', forExternalLead.FirstName__c);
                Util.EmailLog.set('Last Name', forExternalLead.LastName__c);
                Util.EmailLog.set('Website', forExternalLead.CompanyWebsite__c);

                if (forExternalLead.CompanyWebsite__c != null && forExternalLead.CompanyWebsite__c != '') {

                    if (domainsUsed.get(forExternalLead.Domain__c).size() > 0) {
                        Util.EmailLog.setColor(Util.EmailLog.COLOR_ORANGE);
                        Util.EmailLog.set('Message', 'Ignored. Duplicates the value of ' + String.join(new List<String>(domainsUsed.get(forExternalLead.Domain__c)),', '));
                    
                    } else {
                        Util.EmailLog.setColor(Util.EmailLog.COLOR_GREEN);
                        domainsUsed.get(forExternalLead.Domain__c).add(forExternalLead.UUID__c);
                        externalLeadsToInsert.add(forExternalLead);
                        dmlToCandidateMap.put(dmlIndex++,candidateIndex);
                    }
                
                } else {
                    Util.EmailLog.setColor(Util.EmailLog.COLOR_GREEN);
                    externalLeadsToInsert.add(forExternalLead);
                    dmlToCandidateMap.put(dmlIndex++,candidateIndex);
                }

                Util.EmailLog.next();
                candidateIndex++;
            }



            dmlIndex = 0;
            for(Database.SaveResult forSaveResult : Database.insert(externalLeadstoInsert, false)) {
                if (forSaveResult.isSuccess()){
                    Util.EmailLog.set(dmlToCandidateMap.get(dmlIndex),'Message','Inserted with id ' + forSaveResult.getId());
                } else {
                    Util.EmailLog.set(dmlToCandidateMap.get(dmlIndex),'Message','Error. First error: ' + forSaveResult.getErrors()[0].getMessage());
                    Util.EmailLog.setColor(dmlToCandidateMap.get(dmlIndex),Util.EmailLog.COLOR_RED);
                }

                dmlIndex++;
            }

            // @TO-DO put email in a custom setting
            Util.EmailLog.sendMail('test@gmail.com','Import Result');
        
        } catch (Exception e) {
            Util.EmailLog.init(new List<String>());

            // @TO-DO put email in a custom setting
            Util.EmailLog.sendMail('test@gmail.com','Import Leads Error:' + e);            
        }
    }


    private Set<String> extractUUID(List<Object> paramInput) {
        Set<String> uuids = new Set<String>();

        for (Object forRecordObject : paramInput) {
            Map<String,Object> forRecord = (Map<String,Object>)forRecordObject;
            uuids.add(String.valueOf(forRecord.get('uuid')));
        }

        return uuids;

    }
    
}