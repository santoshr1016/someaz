# someaz learn as you go

## Pre-requisite Note: Create SSH Keys for Azure Linux VM and put in a dir

```t
# Create Folder
cd Letsencrypt/
mkdir ssh-keys

# Create SSH Key
cd ssh-keys
ssh-keygen \
    -m PEM \
    -t rsa \
    -b 4096 \
    -C "azureuser@myserver" \
    -f terraform-azure.pem 

** No Passphrase **

# List Files
ls -lrt ssh-keys/

# Files Generated after above command 
Public Key: terraform-azure.pem.pub -> Rename as terraform-azure.pub
Private Key: terraform-azure.pem

# Permissions for Pem file
chmod 400 terraform-azure.pem
```

