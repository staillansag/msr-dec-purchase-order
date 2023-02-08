 #!/bin/bash

echo "Getting Postman environment file for Production environment"
if [ ! -f "${POSTMANENVIRONMENTPRODMSR_SECUREFILEPATH}" ]; then
    echo "Secure file path not present: ${POSTMANENVIRONMENTPRODMSR_SECUREFILEPATH}"
    exit 1
fi

newman run ./resources/test/DecPurchaseOrders.postman_collection.json \
    -e ${POSTMANENVIRONMENTPRODMSR_SECUREFILEPATH} || exit 8
 

