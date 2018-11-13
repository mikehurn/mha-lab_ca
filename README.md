# mha-lab_ca
Configures a SSL Certificate Authority for Lab and development environments. 

# lab_ca

#### Table of Contents

1. [Description](#description)
2. [Setup - The basics of getting started with lab_ca](#setup)
    * [What lab_ca affects](#what-lab_ca-affects)
    * [Setup requirements](#setup-requirements)
    * [Beginning with lab_ca](#beginning-with-lab_ca)
3. [Usage - Configuration options and additional functionality](#usage)
4. [Limitations - OS compatibility, etc.](#limitations)
5. [Development - Guide for contributing to the module](#development)

## Description

The lab_ca module is a SSL Certificate Authority for Lab and development environments.
Please exercise caution if you use this module it was designed be simple and usable. With limited security measures. 
The design goal is to be able generate 'in house' certificates that can be used in web browsers and for server to server communications.
With web browsers you have three main options: add your 'root_ca' as a trusted Root CA to all browsers, use certificates from known trusted CAs or use wildcard certificates.
As our main use is for server to server links, we plan to use a wildcard certificate for all web / browser access to our HAProxy. For internal ssl access we plan to use certificates from our lab_ca.
It also has very simple auto-signing logic for the certificates.


## Setup

### What lab_ca affects

* Warnings or other important notices.

Remember that this is a 'Lab' CA.
Please exercise caution if you use this module it was designed be simple and usable. It has limited security measures. 

The root_ca and sub_ca are by default under /opt.
More to be written:


### Setup Requirements


At the minimum update (in init.pp) the following from the defaults!
```
  String $root_country_name      = 'CA',
  String $root_organization_name = 'MHA Ottawa',
  String $root_common_name       = 'Lab Root CA0',
  String $root_ocsp_subj         = "/C=CA/O=${root_organization_name}/CN=OCSP RootCA Responder",
  String $sub_country_name      = 'CA',
  String $sub_organization_name = 'MHA Ottawa',
  String $sub_common_name       = 'Lab Sub CA0',
  String $sub_ocsp_subj         = "/C=CA/O=${root_organization_name}/CN=OCSP SubCA Responder"
```

Also you may want to change:
```
  $certs_nfs        = '/srv/nfs'
  $certs_base       = "${certs_nfs}/Certificates"
```

When you have it installed you may want to NFS export $certs_base. 

Then you may want to enable:
```
  Boolean $root_ocsp_service_enabled = false,
  Boolean $sub_ocsp_service_enabled  = false,
  Boolean $sub_sign_service_enabled  = false,
```

### Beginning with lab_ca

The very basic steps needed for a user to get the module up and running. This can include setup steps, if necessary, or it can be an example of the most basic use of the module.

In the sub_ca directory:

# Test build and sign a Demo Client cert
```
openssl req -new -config sub-ca.conf -out client.csr -keyout private/client.key
openssl ca -config sub-ca.conf -in client.csr -out client.crt -extensions client_ext
```

# Test build and sign a Demo Server cert
```
openssl req -new -config sub-ca.conf -out server.csr -keyout private/server.key
openssl ca -config sub-ca.conf -in server.csr -out server.crt -extensions server_ext
```

For example a Apache server will require the server.crt, the private/server.key and the sub-ca-chain.crt.


# Test the OCSP responders.
```
cd /opt/root-ca

openssl ocsp -issuer root-ca.crt -CAfile root-ca.crt -cert root-ca-ocsp.crt -url http://127.0.0.1:9080

cd /opt/sub-ca

openssl ocsp -issuer sub-ca.crt -CAfile sub-ca-chain.crt -cert sub-ca-ocsp.crt -url http://127.0.0.1:9081
```

# Test the signing service drop a CSR into the 'server' or the 'client' directories below:
```
$certs_server     = "${certs_base}/Requests/server"
$certs_server_old = "${certs_base}/Requests/server/old"
$certs_client     = "${certs_base}/Requests/client"
$certs_client_old = "${certs_base}/Requests/client/old"
```

When signed the CSR is moved to the matching 'old' directory.
The signed certificate is placed into:
```
$certs_certs      = "${certs_base}/Certificates"
```

## Usage

Include usage examples for common use cases in the **Usage** section. Show your users how to use your module to solve problems, and be sure to include code examples. Include three to five examples of the most important or common tasks a user can accomplish with your module. Show users how to accomplish more complex tasks that involve different types, classes, and functions working in tandem.

## Reference

This Puppet module is in part based on the information in the OpenSSL Cookbook https://www.feistyduck.com/books/openssl-cookbook/

Also with thanks to Google for helping me find many web pages on the subject.


## Limitations

Developed and tested on CentOS 7.5. But should be good for RHEL 7.x.

## Development

At the moment please email suggestions to the code and default config files.

Note: At the moment this code is in the early stages of development it still needs a few enhancements. As time permits or a need crops up I plan to look into them.
Also as it develops I am looking to better follow the current 'best practice' for x509 CAs.


# Todo:
I plan to update the code to work as an intermediate or a root CA.

## Release Notes/Contributors/Etc. **Optional**

If you aren't using changelog, put your release notes here (though you should consider using changelog). You can also add any additional sections you feel are necessary or important to include here. Please use the `## ` header.
