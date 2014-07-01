socore - Solo or zerO COokbook REpo manager
======

Description
===========

This gem manages the root level of a repository of cookbooks. It was written to solve the problem where you need to keep a number of cookbooks inside of a repository for services such as AWS Opsworks but you want to allow them to live independently in their own repositories and easily update them from their origin repository.

SOCORE uses a config file, socore.conf to determine which cookbooks to manage. It clones all of the cookbooks in this config file, removes the .git directory from the local version, creates a lock file and keeps track of the sha of the cookbook repository that has been checked out. It also keeps an eye out for local changes so it knows if it needs to pull the cookbook down again and overwrite local changes. It will only pull updates if needed and lets you know when it has updated a local cookbook directory.

Installation
============

gem install socore

Usage
=====

Create the config file, socore.conf, in the root of your repository.

Example config file...

```
cookbook 'chef-solr', :git => 'git@github.com:phutchins/chef-solr.git'
```

Run `socore` in the root of your repository.

Sample
======

```
$ socore
Config: /Users/phutchins/github/opsworks-master/socore.conf
 - Processing cookbook 'base-cookbook', URI: git@github.com:MYREPO/base-cookbook.git
 base-opsworks needs an update...
 - Processing cookbook 'abcd-chef', URI: git@github.com:MYREPO/abcd-chef.git
 - Processing cookbook 'logstash', URI: git@github.com:phutchins/chef-logstash.git
Cookbooks updated...
Done...
```
