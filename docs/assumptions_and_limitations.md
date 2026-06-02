# Assumptions And Limitations

## Assumptions

- `Brand` is used as the main product identifier across the source tables.
- `VendorNumber` is used as the vendor identifier across the source tables.
- Freight is allocated from vendor level to vendor-product level based on purchase-dollar share within each vendor.
- Average purchase cost is used to estimate unsold inventory cost.
- Inventory snapshot `Price` is used as a reference value, not as direct product cost.

## Limitations

- Inventory cost is estimated because the inventory snapshots do not contain unit cost.
- Some products can appear in sales without a matching purchase row in the same period.
- The final table is built for reporting and analysis, not as a full production warehouse.

## Freight note

Freight is stored separately in `fct_vendor_freight` and then allocated into the final table. This avoids repeating the same vendor freight value on every vendor-product row.
