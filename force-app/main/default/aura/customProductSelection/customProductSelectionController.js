({
    doInit: function (component, event, helper) {
        helper.getColumnDefinitions(component);
        helper.getAllProducts(component);
    },

    handleSort: function(component, event, helper) {
        helper.handleSort(component, event);
    },

    searchProducts : function(component, event, helper) {
        helper.searchProds(component, event);
    },

    updateSelectedText: function (component, event, helper) {
        helper.updateSelectedCount(component);
        component.set("v.isCheckedSelectAll", false);
    },

    showSelectedRows : function (component, event, helper) {
        component.set("v.productsForDisplay", component.get("v.selectedProducts"));    
        component.set("v.showSelectedVisible", false);
    },

    showAllRows : function (component, event, helper) {
        component.set("v.searchValue", '');
        component.set("v.productsForDisplay", component.get("v.allProducts"));
        component.set("v.showSelectedVisible", true);
        component.set("v.valueFamily", []);

    },

    showFilters: function (component, event, helper) {
        component.set("v.isShowFilter", !component.get("v.isShowFilter"));
    },

    applyFilters: function (component, event, helper) {
        helper.addFamilyFiltersWithSearch(component);
    }, 

    selectAll: function (component, event, helper) {
        var isSelectAll = component.get("v.isCheckedSelectAll");
        var productsForDisplay = component.get("v.productsForDisplay");
        if (isSelectAll) {
            for (var prod of productsForDisplay) {
                prod.isSelected = true;
            }
        } else {
            for (var prod of productsForDisplay) {
                prod.isSelected = false;
            }
        }

        component.set("v.productsForDisplay", productsForDisplay);
        helper.updateSelectedCount(component);
    }
})