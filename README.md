socore - Solo or zerO COokbook REpo
======

Description
===========

This gem manages the root level of a repository of cookbooks. It was written to solve the problem where you need to keep a number of cookbooks inside of a repository for services such as AWS Opsworks but you want to allow them to live independently in their own repositories and easily update them from their origin repository.

SOCORE uses a config file, socore.conf to determine which cookbooks to manage. It clones all of the cookbooks in this config file, removes the .git directory from the local version, creates a lock file and keeps track of the sha of the cookbook repository that has been checked out. It also keeps an eye out for local changes so it knows if it needs to pull the cookbook down again and overwrite local changes. It will only pull updates if needed and lets you know when it has updated a local cookbook directory.

Installation
============

```
gem install socore
```

Usage
=====

Create the config file, `socore.conf`, in the root of your repository.

Example config file...

```
cookbook 'chef-solr', :git => 'git@github.com:phutchins/chef-solr.git'
```

Run `socore` in the root of your repository.

Sample
======

Sample run...
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

Resulting lock file `socore.lock` ...
```
cookbook 'base-cookbook', :git_sha => '29403bae6ee12570a108c31f7a1251745d8b9a26', :dir_hash => 'f2ecef31a58893417f34b9db78788bac'
cookbook 'abcd-chef', :git_sha => '088978e75a867e1cf196cabfd0b87b7eec0a8d9f', :dir_hash => 'faab05547892365d55eec96fc6003de4'
cookbook 'logstash', :git_sha => '6d1025df1202da833ecf2e83b45a2056697047a7', :dir_hash => 'bc88db6b79b2824660a78b6bdc68a403'
```

TODO
====

- Add ability to pin version numbers of cookbooks via repository tag name

### License

socore is released under the Apache 2.0 license. See the [LICENSE](LICENSE) file for details.

Specific components of fleet use code derivative from software distributed under other licenses; in those cases the appropriate licenses are stipulated alongside the code.
