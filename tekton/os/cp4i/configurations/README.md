# CP4i configurations

CP4i containers expect to to be provided with configurations that contain policies, server.conf.yaml overrides, etc.

## default-policy server.conf.yaml

A configuration called `default-policy` is needed in order to specify the default policy project for the
integration server to use. This allows the JDBC code to location the JDBC policy that specifies the location
of the DB2 server.

The configuration should be of type server.conf.yaml and contain the following:
```
Defaults:
  policyProject: 'CTPolicies'
```

## teajdbc-policy Policy project

A configuration called `teajdbc-policy` is needed in order to specify the location of the DB2 database.

The configuration should be of type "Policy project" and contain a ZIP file containing the CTPolicies 
policy project from this directory, with the location information in [CTPolicies/TEAJDBC.policyxml](CTPolicies/TEAJDBC.policyxml) 
updated to point to the correct server location.

Once the location has been updated, the ZIP file can be created by running 
```
zip -r teajdbc-policies.zip CTPolicies
```
or by using other ZIP tools. The eventual file contents should look as follows:
```
Archive:  teajdbc-policy.zip
  Length      Date    Time    Name
---------  ---------- -----   ----
        0  2022-10-22 22:04   CTPolicies/
      241  2022-10-22 22:03   CTPolicies/policy.descriptor
     1421  2022-10-22 22:04   CTPolicies/TEAJDBC.policyxml
---------                     -------
     1662                     3 files
```

## teajdbc setdbparms.txt

A configuration called `teajdbc` is needed in order to specify the credentials used to connect to DB2 via JDBC.

The configuration should be of type setdbparms.txt and contain the following:
```
jdbc::tea USERNAME PASSWORD
```
with the correct user and password supplied.

