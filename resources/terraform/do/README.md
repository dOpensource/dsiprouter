## Installing dSIPRouter Using Terraform on Digital Ocean

1. Generate an SSH key if you don't already have one

2. Configure the SSH key into your Digital Ocean Account

3. Obtain a Digital Ocean API key and store the key as an environment variable

```
export DIGITALOCEAN_TOKEN='put your token here'
```

4. Copy terraform.tfvars.sample to terraform.tfvars

```
cp terraform.tfvars.sample terraform.tfvars
```
5. Modify terraform.tfvars so that it overrides your variables, which is located in variables.tf.  The pvt_key_path is the location of your private key.  The pub_key_name is the name of the public key you defined when you uploaded your SSH key.  The dsiprouter_prefix is the prefix that will be concatenated to the name of the droplet that will be created.  The number_of_environments is used to specify how many instances will be crated.

```
pvt_key_path="your path to key"
dns_domain="dsiprouter.net"
dns_hostname="training"
number_of_environments=1
pub_key_name="dopensource-training"
additional_commands="echo"
```

All of the variables and any default values can be found in variables.tf.  

6. Create a new instance of dSIPRouter

The following command will create a new instance of dSIPRouter based on the master branch.  The OS image will be Debian 11 and the dsiprouter_prefix will be overriden by demo.

```
terraform apply -var branch=master
```

If you want to create a demo instance of dSIPRouter in your Digitalocean environment with a DNS record use this.  
Note, you will need to change the dns_demo_domain variable to a domain that you have hosted with DigitalOcean.

```
terraform apply -var branch=master -var dns_hostname=test -var dns_demo_domain=dsiprouter.org -var additional_commands='dsiprouter setcredentials -dc admin:ZmIwMTdmY2I5NjE4'
```

7. Destroy your instance if you are done with it by using the terraform destroy command

```
terraform destroy
```

## Need Help?

We offer paid support for this Terraform script!  You can purchase 2 hours of support from [here](https://dopensource.com/product-category/prepaid-support/)
