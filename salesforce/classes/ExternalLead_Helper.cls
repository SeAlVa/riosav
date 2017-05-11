public class ExternalLead_Helper {

    private static Pattern urlPattern = pattern.compile('https?://([^\\./]+\\.)?([^\\./]+\\.[^\\./]+)((/.*)|$)');

    public static String getDomainFromUrl(String paramUrl){
        
        Matcher theMatcher = urlPattern.matcher(paramUrl);
        return theMatcher.matches() && theMatcher.groupCount() > 2?theMatcher.group(2):null;
    }
    
    public static String getDomainFromEmail(String paramEmail){

        if(paramEmail != null && paramEmail.contains('@')) {
            return paramEmail.split('@')[1];
        
        } else {
            return null;
        }
    }
    
}