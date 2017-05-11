public without sharing class Util {
  
    public static Message messages {get{if (messages == null) messages = new Message(); return messages;} private set;}
    public static PostMan postman {get{if (postman == null) postman = new PostMan(); return postman;} private set;}
    public static Emails emails {get{if (emails == null) emails = new Emails(); return emails;} private set;}
    public static EmailLog emailLog {get{if (emailLog == null) emailLog = new EmailLog(); return emailLog;} private set;}
    public static Organization org {get{if(org == null) org = [SELECT Id, IsSandbox FROM Organization]; return org;} private set;}
    
    public class message {
    	Integer confirm {get{if (confirm == null) confirm = 0; return confirm;}private set;}
    	Integer info {get{if (info == null) info = 0; return info;}private set;}
    	Integer warning {get{if (warning == null) warning = 0; return warning;}private set;}
    	Integer error {get{if (error == null) error = 0; return error;}private set;}

    	public void addConfirm(Object paramObject) {
      		if(Apexpages.currentPage() != null)
        		ApexPages.addmessage(new ApexPages.message(ApexPages.severity.CONFIRM,++confirm + ' : ' + paramObject));
      		else
        		System.debug('CONFIRM: ' + ++confirm + ' : ' + paramObject);
    		}
        public void addInfo(Object paramObject){
            if(Apexpages.currentPage() != null)
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.INFO,++info + ' : ' + paramObject));
            else
                System.debug('INFO: ' + ++confirm + ' : ' + paramObject);
        }
        public void addWarning(Object paramObject) {
            if(Apexpages.currentPage() != null)
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,++warning + ' : ' + paramObject));
            else
                System.debug('WARNING: ' + ++confirm + ' : ' + paramObject);
        }
        public void addError(Object paramObject) {
            if(Apexpages.currentPage() != null)
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,++error + ' : ' + paramObject));
            else
                System.debug('ERROR: ' + ++confirm + ' : ' + paramObject);
        }
  	}
    
    public class PostMan{
        
        public HttpResponse doGet(String paramEndpoint, Map<String,String> paramHeaders) {
            Http http = new Http();
            HttpRequest req = new HttpRequest();
            req.setEndpoint(paramEndpoint);
            req.setMethod('GET');
            req.setTimeout(120000);
            if(paramHeaders != null){
                for (String forHeaderName : paramHeaders.keySet()) {
                    req.setHeader(forHeaderName, paramHeaders.get(forHeaderName));
                }
            }
            return http.send(req);
        }
    }
    
    
     public class Emails {
        public final String TO='to',ATTACHMENTS='attachments',TEXT_BODY='textBody',HTML_BODY='htmlBody',SUBJECT='subject',CC='cc',BCC='bcc',REPLY_TO='replyTo',SENDER_NAME='senderName',REFERENCES='references',CHARSET='charset',ORG_EMAIL_ID='orgEmailId',TEMPLATE_ID='templateId',TARGET_ID='targetId',WHAT_ID='whatId',SAVE_AS_ACTIVITY='saveAsActivity';
        
        public void send(Map<String,Object> paramOptions){
            send(get(paramOptions));
        }
        public void send(Messaging.SingleEmailMessage paramMail) {
            if(!Test.isRunningTest()) {
                try {
                    Messaging.sendEmail(new Messaging.SingleEmailMessage[]{paramMail});
                } catch (Exception e) {
                    if (!Util.org.IsSandbox) throw e;
                }
            }
        }
        
        public Messaging.SingleEmailMessage get(Map<String,Object> paramOptions) {
            Set<String> validOptions = new Set<String>{TO,TEXT_BODY,HTML_BODY,SUBJECT,CC,BCC,REPLY_TO,SENDER_NAME,REFERENCES,CHARSET,ORG_EMAIL_ID,TEMPLATE_ID,TARGET_ID,WHAT_ID,SAVE_AS_ACTIVITY};
            if(validOptions.containsAll(paramOptions.keySet())) {
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                List<String> to = extractEmails(paramOptions.get(TO));
                if(!to.isEmpty()) mail.setToAddresses(to);
                List<String> cc = extractEmails(paramOptions.get(CC));
                if(!cc.isEmpty()) mail.setCcAddresses(cc);
                List<String> bcc = extractEmails(paramOptions.get(BCC));
                if(!bcc.isEmpty()) mail.setBccAddresses(bcc);
                
                if(paramOptions.get(SUBJECT) != null) mail.setSubject((String)paramOptions.get(SUBJECT));
                String replyTo = (String) paramOptions.get(REPLY_TO);
                if(isValid(replyTo)) mail.setReplyTo(replyTo);

                String senderName = (String) paramOptions.get(SENDER_NAME);
                if(senderName != null) mail.setSenderDisplayName(senderName);

                String textBody = (String) paramOptions.get(TEXT_BODY);
                if(textBody != null) mail.setPlainTextBody(textBody);
                String htmlBody = (String) paramOptions.get(HTML_BODY);
                if(htmlBody != null) mail.setHtmlBody(htmlBody);

                String references = (String) paramOptions.get(REFERENCES);
                if(references != null) mail.setReferences(references);

                String charset = (String) paramOptions.get(CHARSET);
                if(charset != null) mail.setCharset(charset);

                Id orgEmailId = (ID) paramOptions.get(ORG_EMAIL_ID);
                if(orgEmailId != null) mail.setOrgWideEmailAddressId(orgEmailId);


                Id targetId = (ID) paramOptions.get(TARGET_ID);
                if(targetId != null) mail.setTargetObjectId(targetId);
                
                Id templateId = (ID) paramOptions.get(TEMPLATE_ID);
                if(templateId != null)  mail.setTemplateId(templateId);

                Id whatId = (Id) paramOptions.get(WHAT_ID);
                if(whatId != null) mail.setWhatId(whatId);
                
                Boolean saveAsActivity = (Boolean) paramOptions.get(SAVE_AS_ACTIVITY);
                if(saveAsActivity != null) mail.setSaveAsActivity(saveAsActivity);

                return mail;
            } else {
                paramOptions.keySet().removeAll(validOptions);
                throw new EmailsException('Invalid options: ' + String.join(new List<String>(paramOptions.keyset()),', '));
            }
        }

        private List<String> extractEmails(Object param) {
            List<String> returned = new List<String>();
            if(param instanceof String) { // one destination
                if(isValid((String)param))returned.add((String)param);
            } else if (param instanceof List<String>) { // list of destinations
                for(String forTo : (List<String>)param) if(isValid(forTo)) returned.add(forTo);
            } else if (param instanceof Set<String>) { // set of destinations
                for(String forTo : (Set<String>)param) if(isValid(forTo)) returned.add(forTo);
            } else if (param != null) { // none of the above and not null
                throw new EmailsException('Invalid type received. Received: ' + param);
            }
            return returned;
        }

        
        private boolean isValid(String emailAddress){
            return emailAddress == null?false:Pattern.matches('[a-zA-Z0-9\\.\\!\\#\\$\\%\\&\\*\\/\\=\\?\\^\\_\\+\\-\\`\\{\\|\\}\\~\'._%+-]+@[a-zA-Z0-9\\-.-]+\\.[a-zA-Z]+', emailAddress);
        }
    }

    public class EmailsException extends Exception{}
    
    
    public class EmailLog {
        public String COLOR_ORANGE='bisque',COLOR_GREEN='lightgreen',COLOR_RED='lightcoral';
        
        List<String> logHeaders;
        Map<String,Integer> logHeadersMap;
        List<List<String>> logContent;
        List<String> currentContent;
        
        public void init(List<String> paramHeaders) {
            if (new Set<String>(paramHeaders).contains('__color')) throw new EmailLogException('__color is a reserved Header');
            Integer i = 1;
            logHeaders = new List<String>{'__color'};
            logHeadersMap = new Map<String,Integer>();
            for(String forHeader : paramHeaders) {
            	logHeaders.add(forHeader);
                logHeadersMap.put(forHeader,i++);
            }
            logContent = new List<List<String>>();
            initCurrentContent();
        }
        
        private void initCurrentContent(){
            currentContent = new List<String>();
            for(String forHeaders : logHeaders){
                currentContent.add('');
            }
            setColor('#c0c0c0');
        }
        public void next(){
            logContent.add(currentContent);
            
            initCurrentContent();
        }
        
        public void set(String paramHeader, String paramContent){
            currentContent.set(logHeadersMap.get(paramHeader),paramContent);
        }

        public void set(Integer paramRow, String paramHeader, String paramContent){
            logContent.get(paramRow).set(logHeadersMap.get(paramHeader),paramContent);
        }
        
        public void setColor(String paramColor) {
            currentContent.set(0,paramColor);
        }

        public void setColor(Integer paramRow, String paramColor) {
            logContent.get(paramRow).set(0,paramColor);
        }
        
        public void sendMail(String paramTo, String paramSubject){
            next();
            String html = '';
            
            logHeaders.remove(0);
            html += '<table border="0" cellspacing="1" cellpadding="0" width="100%" bgcolor="#c0c0c0"><thead><tr style="background-color:lightgoldenrodyellow"><th>' + String.join(logHeaders,'</th><th>') + '</th></tr></thead><tbody>';
            
            for(List<String> forLogRow : logContent) {
                html += '<tr style="background-color:' + forLogRow.remove(0) + '"><td>' + String.join(forLogRow,'</td><td>') + '</td></tr>';
            }
            
            html += '</tbody></table>';
            
            
            Util.emails.send(new Map<String,String>{
                Util.emails.TO => paramTo,
                Util.emails.SUBJECT => paramSubject,
                Util.emails.HTML_BODY => html
            });
            
            logHeadersMap.clear();
            logHeaders.clear();
            logContent.clear();
        }
    }
    
    public class EmailLogException extends Exception{}
}