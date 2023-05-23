({
    fetchAccounts : function(component, helper) {
        debugger;
       var action = component.get("c.getContacRelatedBigObjectsForAura");
        action.setParams({
            recordId : component.get("v.accountId")
        });
        action.setCallback(this, function(response){
            if(response.getState() === "SUCCESS"){
                var result = response.getReturnValue();
                component.set("v.listOfAccounts",result);
                helper.preparePagination(component, result);
            }
        });
        $A.enqueueAction(action);
    },
     
    preparePagination: function (component, records) {
        debugger;
        let countTotalPage = Math.ceil(records.length / component.get("v.pageSize"));
        let totalPage = countTotalPage > 0 ? countTotalPage : 1;
        component.set("v.totalPages", totalPage);
        component.set("v.currentPageNumber", 1);
        component.set("v.totalRecords", records.length);
        this.setPaginateData(component);
    },
     
    setPaginateData: function(component){
        debugger;
        let data = [];
        let pageNumber = component.get("v.currentPageNumber");
        let pageSize = component.get("v.pageSize");
        let accountData = component.get('v.listOfAccounts');
        let currentPageCount = 0;
        let x = (pageNumber - 1) * pageSize;
        currentPageCount = x;
        for (; x < (pageNumber) * pageSize; x++){
            if (accountData[x]) {
                data.push(accountData[x]);
                currentPageCount++;
            }
        }
        component.set("v.paginationList", data);
        component.set("v.currentPageRecords", currentPageCount);
    },
     
    sortData: function (cmp, fieldName, sortDirection) {
        debugger;
        var fname = fieldName;
        var data = cmp.get("v.listOfAccounts");
        var reverse = sortDirection !== 'asc';
        data.sort(this.sortBy(fieldName, reverse))
        cmp.set("v.listOfAccounts", data);
        this.setPaginateData(cmp);
    },
     
    sortBy: function (field, reverse) {
        debugger;
        var key = function(x) {return x[field]};
        reverse = !reverse ? 1 : -1;
        return function (a, b) {
            return a = key(a), b = key(b), reverse * ((a > b) - (b > a));
        }
    },
})