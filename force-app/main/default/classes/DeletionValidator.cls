/**
* @author Gavin Palmer (gavinhughpalmer@gmail.com)
* @version 1.0
* @description This class will be used to validate the deletion of objects which are not covered by profiles
*
* 2019-02-11 : Gavin Palmer - Original
**/
public without sharing class DeletionValidator extends Triggerable {

    @testVisible private static final String NOT_ALLOWED_DELETE = 'You do not have the correct permissions to delete this record. Please contact your system administrator';

    public override void register(SObjectTriggerWrapper wrappedSObject) {
        if (ConfigurationManager.getInstance().isNotAllowedDelete()) {
            wrappedSObject.getSObject().addError(NOT_ALLOWED_DELETE);
        }
    }
}