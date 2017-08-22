
## The Stack

- Language: Ruby
- Framework: [sinatra](http://www.sinatrarb.com/)
- PSQL

## To Run:
- `ruby rtchallenge.rb`

## Requirements:
- `ENV['USER']='user'` user to login with
- `ENV['USER_PW']='password1'` password to login with
- `ENV['PT_TOKEN']='d133a1b130e414e794958136fd6e8a76'`
- `ENV['PT_PROJECTS']='2088251, 2088250'` pivotal projects
- `ENV['RELEASE_LABEL']=''` Name of current release tag by PM.

## Additional Info:

### [Pivotal login](https://www.pivotaltracker.com/signin):
- user: `nate+test1@reviewtrackers.com`
- pw: `Password1!`

##########################################
## Solution
### Run locally
```
docker pull postgres
docker run -it --rm --name rtchallenge -e POSTGRES_PASSWORD=password1 -e POSTGRES_DB=rtchallenge -e POSTGRES_USER=user1 -p 5432:5432 -d postgres
docker volume create --name app-logs
docker run -it --rm -e "xpack.monitoring.enabled=false" -v <rt_challenge_dir>/logstash/logstash.conf:/usr/share/logstash/pipeline/logstash.conf -v app-logs:/var/log/piv_app/ docker.elastic.co/logstash/logstash:5.5.1
docker run -it --rm -p 4567:4567 -v app-logs:/var/log/piv_app/ --link rtchallenge:rtchallenge rt_cc
```

#### To Deploy to Production
Setup up terraform: https://www.terraform.io/intro/getting-started/install.html
As defined in the defaults file, when setting up an AWS key, in your AWS config and credentials, make a challenge-terraform user.
If standing up new infrastructure in a new account, delte the .tfstate file and run
```
terraform init
```
All security groups should provide access between rds and ec2 instance. Additionally, there is a pem file you may need to generate called priv_account_key within AWS. This pem file will let you shell into the ec2 instance. You will also have to update the ingress point for the ec2 instance with the CIDR block of either your local machine, or local network. Once you have taken these steps, run
```
terraform plan
```
which will show you all the actions terraform will take. Double check the output to make sure all actions are expected. If everything looks good, run
```
terraform apply
```
If no errors come back, you should now have a running database, an autscaling group with and ec2 instance, all part of an ecs cluster. You should be able to shell into the ec2 instance:
```
ssh -i /path/to/pem ec2-user@<public-ip>
```
Once on, run 
```
sudo su -
docker ps
```
and you should see at least one docker container running the ecs-agent.

### Update db endpoint
I did not generate route 53 records and create anytime of dns. So we will need to update the app to point to the new rds instance. In the env.rb file, update the PROD_DATABASE_URL to use the endpoint as defined in rds console for the new rds instance.
Rebuild the docker image:
```
docker build / -t wfortin136/rt_cc:latest
docker push wfortin136/rt_cc:latest
```
I have made rt_cc a private repo under my dockerhub account. Feel free to replace wfortin with your own dockerhub account. If you change, there are two places you must update. 
- ecs/container-def.json : line 16
- terraform/ecs_piv.tf : line 101

First time steps for db migrations:
This is a bit of a hack, but for the purposes of this challenge, I think it suffices. To create the schemas and the db and seed the db, you need to run the migrations on the docker container
```
ssh -i /path/to/pem ec2-user@<public-ip>
sudo su -
docker ps
docker exec -it <sha of container from docker ps> bash
rake db:migrate RACK_ENV=production
rake db:migrate:up VERSION=201702211436
```

At this point everything should be working. You should be able to access the pivotal app through the public ip of the ec2 instance you created. Keep in, this is part of an autoscaling group, so if the instance goes down, a new one will be created with a new public ip. The only thing this cluster is missing is a load balancer that would handle dynamic ip routing.

Additionally, there is an added logstash container for log shipping. For now, I just have it sending access logs to stdout. You can view the logs as follows
```
docker ps
docker logs -f <sha of logstash container>
```
Then hit the public ip, and you should see access logs dump.

I have used this repo to spin up a cluster running this exact configuration, which can be seen here: http://http://54.224.5.161

