({
    showToast :function (title, message, type) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": title,
            "message": message,
            "type": type
        });
        toastEvent.fire();
    },

    sortExistingProducts :function (existingProducts) {
        var sortDirection = 'asc';
        existingProducts.sort((this.sortBy('fieldForSorting', sortDirection === 'asc' ? 1 : -1)));
        return existingProducts;
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
    }
})