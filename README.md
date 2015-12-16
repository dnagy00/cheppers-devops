# cheppers-devops
DevOps Challenge

# Requirements
- fog/aws
- colorize
- highline/import
- thor
- metainspector

# Description
The script can CREATE, DELETE and STOP any AWS Ec2 Instances.
But it can install LAMP stack with a fresh drupal and after this process can check the drupal site status.
The best usage is that if you run this on a Chef Workstation!

# Installation

 - Clone the repository (on a Chef Workstation)
 - Copy lamp-drupal folder to the cookbooks
 - Go into the directory and `berks install` to install the cookbook dependencies
 - Edit the files in ***lamp-drupal/attributes***
 - Go to the directory where ***cheppers.rb*** is located
 - Type `bundle install` to install the required gems
 - Edit the ***secrets.json*** file and add your security credentials


# Usage

```ruby
ruby cheppers.rb [commands] [arguments]
```

***
Help and command list

```ruby
ruby cheppers.rb --help
```

***

Creating EC2 instance:

> *With this command you can create instance, install lamp and drupal and check the drupal installation status at the same time.*

```ruby
ruby cheppers.rb create [arguments]
```

| Argument      | Value / Default	| Description  |
| ------------- |:-------------:| ------------:|
| -c  			| secrets.json  | Credentials file |
| -r 			| eu-west-1 	| Region	   |
| -s 			| knife 		| SSH Key name |
| -z 			| eu-west-1b 	| Availability Zone |
| -i 			| ami-47a23a30 	| AMI image    |
| -g 			| cheppers-doc-main | Security Group ID |
| -t 			| t2.micro 		| Instance Type |
| -n 			| Instance name | Instance Name |
| -timeout		| 600 			| Connection timeout |
| -tags			| Array			| Tags |

***
Install LAMP Stack and a fresh Drupal:
```ruby
ruby cheppers.rb install [ID] [arguments]
```
| Argument      | Value              | Description  	|
| ------------- |:------------------:| ----------------:|
| -c  			| secrets.json  	 | Credentials file |
| -r 			| eu-west-1 		 | Region	  	 	|

***
Deleting EC2 instance:
```ruby
ruby cheppers.rb delete [ID] [arguments]
```

| Argument      | Value         | Description  |
| ------------- |:-------------:| ------------:|
| -c  					| secrets.json  | Credentials file |
| -r 						| eu-west-1 		| Region	   |

***

Stopping EC2 instance:
```ruby
ruby cheppers.rb stop [ID] [arguments]
```

| Argument      | Value         | Description  |
| ------------- |:-------------:| ------------:|
| -c  					| secrets.json  | Credentials file |
| -r 						| eu-west-1 		| Region	   |


***

Checking drupal installation:
```ruby
ruby cheppers.rb check [URL]
```
