({
    getColumnDefinitions: function (component) {
        var columns = [
            {label: 'Product Name ', fieldName: 'prodName', type: 'text', sortable: true, arrowDirection : 'arrowdown'},
            {label: 'Product Code', fieldName: 'ProductCode', type: 'text', sortable: true, arrowDirection : 'arrowdown'},
            {label: 'List Price', fieldName: 'UnitPrice', type: 'currency', typeAttributes: { currencyCode: 'GBP'}, sortable: true, arrowDirection : 'arrowdown',style : 'width:130px;'},
            {label: '2 Ad Price', fieldName: 'X2_Adult_List_Price__c', type: 'currency', typeAttributes: { currencyCode: 'GBP'}, sortable: true, arrowDirection : 'arrowdown', style : 'width:130px;'},
            {label: 'Product Description', fieldName: 'prodDesc', type: 'text', sortable: true, arrowDirection : 'arrowdown'},
            {label: 'Product Family', fieldName: 'prodFamily', type: 'text', sortable: true, arrowDirection : 'arrowdown'}
        ];

        component.set("v.productColumns", columns);
        component.set("v.savedSelections", []);
    },

    getAllProducts : function(component) {
        var actionGetProds = component.get("c.getLeasureProducts");
        actionGetProds.setParams({
            isInit: true,
            prBookId: component.get("v.selectedPricebookId"),
            existingProductList : component.get("v.listExistingId")
        });
                    
        actionGetProds.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                    var products = response.getReturnValue().products;
                    for (var prod of products) {
                        prod.prodName = prod.Product2.Name;
                        prod.prodDesc = prod.Product2.Description;
                        prod.prodFamily =  prod.Product2.Family;
                    }
                    component.set("v.allProducts", products);
                    component.set("v.productsForDisplay", products);

                    component.set("v.supplementsMap", response.getReturnValue().supplements);
            } else {
                this.showToast('Error!', response.getError(), 'error');
            }
        });
        $A.enqueueAction(actionGetProds);
    }, 

    handleSort: function(component, event) {
        try {
            var sortedBy = event.currentTarget.dataset.field;
            var sortDirection = 'asc';
            var productColumns = component.get("v.productColumns");

            var cloneData = component.get("v.productsForDisplay").slice(0);
            cloneData.sort((this.sortBy(sortedBy, sortDirection === 'asc' ? 1 : -1)));
            var sortDirection = '';
            for (var col of productColumns) {
                if (col.fieldName == sortedBy) {
                    sortDirection = col.arrowDirection != 'arrowdown'? 'asc': 'desc';
                    col.arrowDirection = col.arrowDirection == 'arrowdown'? 'arrowup': 'arrowdown';
                } else {
                    col.arrowDirection = 'arrowdown';
                }
            }

            cloneData.sort((this.sortBy(sortedBy, sortDirection === 'asc' ? 1 : -1)));
            component.set('v.productsForDisplay', cloneData);
            component.set('v.sortDirection', sortDirection);
            component.set('v.sortedBy', sortedBy);
            component.set('v.productColumns', productColumns);
        } catch (error) {
            this.showToast('Error!', JSON.stringify(error), 'error');
        }

    },

    sortBy: function(field, reverse, primer) {
        var key = primer
            ? function(x) {
                  return primer(x[field]);
              }
            : function(x) {
                  return x[field];
              };

        return function(a, b) {
            a = key(a);
            b = key(b);
            return reverse * ((a > b) - (b > a));
        };
    },

    searchProds: function (component, event) {
        var searchValue = component.get("v.searchValue");
        var allProducts = component.get("v.allProducts");

        var cloneData = allProducts.slice(0);
        var newData = [];

        for (var prod of cloneData) {
            if (prod.Product2.Name.toLowerCase().indexOf(searchValue.toLowerCase()) !== -1) {
                newData.push(prod);
            }
        }
        component.set("v.productsForDisplay", newData);
    },

    updateSelectedCount : function(component) {
        try {
            var allRows = component.get("v.allProducts");
            var selectedRows = [];
            for (var prod of allRows) {
                if (prod.isSelected) {
                    selectedRows.push(prod);
                }
            }
            component.set("v.selectedProducts", selectedRows);
            component.set("v.selectedRowsCount", selectedRows.length);
        } catch (error) {
            this.showToast('Error!',JSON.stringify(error), 'error');
        }
    }, 

    addFamilyFiltersWithSearch : function(component) {
        var selectedFamilies = component.get("v.valueFamily");
        var searchValue = component.get("v.searchValue");
        var allProducts = component.get("v.allProducts");
        
        var cloneData = allProducts.slice(0);
        var newData = [];
        for (var prod of cloneData) {
            if ((prod.Product2.Name.toLowerCase().indexOf(searchValue.toLowerCase()) !== -1)
                && (selectedFamilies.includes(prod.Product2.Family) || $A.util.isEmpty(selectedFamilies))) {
                newData.push(prod);
            }
        }
        component.set("v.productsForDisplay", newData);
    }, 

    showToast :function (title, message, type) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": title,
            "message": message,
            "type": type
        });
        toastEvent.fire();
    }
})