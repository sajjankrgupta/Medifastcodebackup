/****************************************************************************
* Name                             : AccountTriggerHandlerTest
* Author                           : NTT Data Services
* Date                             : June - 2021
* Requirement/Project Name         : Agent Productivity
* Requirement/Project Description  : AG-312,AG-458,AG-456
* This class contains unit tests for validating the behavior of Apex classes
* and triggers.
* See the Apex Language Reference for more information about Testing and Code Coverage.
***************************************************************************/

@isTest
public class AccountTriggerHandlerTest 
{
    @testSetup static void accountUpdate()
    {
        Account acc = New Account(Name='Test Account', First_Name__c='Test', Last_Name__c='Account',phone='3392245674');
        insert acc;
        system.assertEquals('Test Account', [select name from account].name ,  'Account is not created');
        
         user intUser = [select id from user where name='Integrations User'];
        system.runAs(intUser)
        {
            Account acc1 = New Account(Name='Test Account1', First_Name__c='Test', Last_Name__c='Account1',phone='3392245675');
            insert acc1;
        }
    }
    
    public static testMethod void checkvalidphoneupdate()
    {
        Account a  = [select id,first_Name__c,Last_Name__c,phone from Account where Name='Test Account'];
        a.phone='3392245679';
        update a;
        system.assertEquals('13392245679', [select phone from account where Name='Test Account'].phone , 'Phone format did not complete');
    }
    
    public static testMethod void checkInvalidphoneupdate()
    {
        Account a  = [select id,first_Name__c,Last_Name__c,phone from Account where Name='Test Account'];
        a.phone='9999';
        try {
            update a;
        } catch (DMLException e) {
            system.debug('Exception occured');
            system.assertNotEquals('9999', [select phone from account where Name='Test Account'].phone , 'Exception occured due to Invalid phone');
        }   
    }
    
    public static testMethod void checkInvalidrequesttoFormat()
    {
        Account a  = [select id,first_Name__c,Last_Name__c,phone from Account where Name='Test Account'];
        a.phone=null;
        try {
            update a;
        } catch (DMLException e) {
            system.debug('Exception occured');
            system.assertNotEquals(null, [select phone from account where Name='Test Account'].phone , 'Phone field is null');
        }
    }
    
    
    public static testMethod void checkUpdatefromIntUser()
    {
         user intUser = [select id from user where name='Integrations User'];
         List<account> acclst = new list<account>();
        system.runAs(intUser)
        {
            for( Account a  : [select id,first_Name__c,Last_Name__c,phone,name from Account where Name='Test Account1'])
            {
                a.phone='3392245679';
                acclst.add(a);  
            } 
            update acclst;
        }
            system.assertNotEquals('13392245679', [select phone from account where Name='Test Account1'].phone , 'Phone update did not complete as last modified by is Integration user');
        }  
    }