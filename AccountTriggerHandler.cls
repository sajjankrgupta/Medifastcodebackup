/**************************************************************************
* Name                             : AccountTriggerHandler
* Author                           : NTT Data Services
* Date                             : June - 2021
* Requirement/Project Name         : Agent Productivity
* Requirement/Project Description  : AG-312,AG-458,AG-456
/**************************************************************************/
public with sharing class AccountTriggerHandler 
{
public static boolean hasExecuted = false;
private boolean isExecutingflag = false;
private integer batchSize = 0;

/*** instantiates a handler instance  */	
public AccountTriggerHandler(boolean isExecuting, integer size){
    isExecutingflag = isExecuting;
    batchSize = size;
}

public class MyException extends Exception {}


/*********************************************************************************
* Method Name: updateAccFields
* Author: NTT Data Services
* Date: June - 2021
* Params: List<Account>,Map<Id, Account>  
* Return: Null
* Requirement: Initial method to check the last modified by and then calls the method 
performPhoneFormatting to format phone number.
*********************************************************************************/

public void updateAccFields(List<Account> accountlst,Map<Id,Account> triggerOldMap)
{
    Id userId = [select id from user where name='Integrations User'].id;
    
        for(account acc :accountlst)
        {
            if(UserInfo.getUserId()<>userId)
            {
                    Account oldAccount = triggerOldMap.get(acc.ID);
                    if(acc.phone !=null || acc.phone != oldAccount.phone)
                    {
                        getCountryCode(accountlst);
                    }
            }
        }
}


/*********************************************************************************
* Method Name: getCountryCode
* Author: NTT Data Services
* Date: June - 2021
* Params: List<Account>  
* Return: Null
* Requirement: Retrives country code and calls method getPhoneformat to retrieve formatted number.
*********************************************************************************/

public void getCountryCode(List<Account> accountlst)
{
    List<Account> accLst = new List<Account>(accountlst);
    
    String invalidNumbers = '[^0-9]';               
    Schema.DescribeFieldResult fieldResult = User.Countrycode.getDescribe();
    List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
    Map<string,string> countrycodeMap= new Map<string,string>();
    string countrycode;
    for( Schema.PicklistEntry f : ple)
    {
        countrycodeMap.put(f.getLabel() , f.getValue());
    }    
    for (account acc : accLst)
    {
        acc.Phone_Country__c = acc.Phone_Country__c<>null?acc.Phone_Country__c:'United States';
        if(getPhoneformat(acc.phone,countrycodeMap.get(acc.Phone_Country__c))=='Invalid phone')
        {
            acc.adderror('Invalid phone, please check!');
        }
        else
        {
            try
            {
                if(acc.phone<>null)
                {
                    acc.Phone=getPhoneformat(acc.phone,countrycodeMap.get(acc.Phone_Country__c)).replaceAll(invalidNumbers, '' );
                }
            }
            catch( Exception e)
            {
                system.debug('Exception occured' + e.getMessage());
            }
        }
    }  
}


/*********************************************************************************
* Method Name: getPhoneformat
* Author: NTT Data Services
* Date: June - 2021
* Params:string phonenumber,string country  
* Return: string (phone number)
* Requirement: Retrives phone format using libPhonenumber.
*********************************************************************************/


public static string getPhoneformat(string phonenumber,string country) {  
    string formattedphone;
    noltic_libphone.PhoneNumberUtil phoneUtil =
        noltic_libphone.PhoneNumberUtil.getInstance();
    try {
        noltic_libphone.PhoneNumber numberProto = phoneUtil.parse(phonenumber, country);
        Boolean isValid = phoneUtil.isValidNumber(numberProto);
        if(!isValid)
        {
            return 'Invalid phone';
        }
        formattedphone= (phoneUtil.format(numberProto, noltic_libphone.PhoneNumberUtil.PhoneNumberFormat.INTERNATIONAL));
    }
    catch (noltic_libphone.NumberParseException e) 
    {
        System.debug('NumberParseException was thrown: ' + e);
    }
    system.debug('Before return ' + formattedphone);
    return formattedphone;
}
}