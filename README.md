
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


## Solution
# To run locally
```docker pull postgres
docker run -it --rm --name rtchallenge -e POSTGRES_PASSWORD=password1 -e POSTGRES_DB=rtchallenge -e POSTGRES_USER=user1 -p 5432:5432 -d postgres
docker volume create --name app-logs
docker run -it --rm -e "xpack.monitoring.enabled=false" -v <rt_challenge_dir>>/logstash/logstash.conf:/usr/share/logstash/pipeline/logstash.conf -v app-logs:/var/log/piv_app/ docker.elastic.co/logstash/logstash:5.5.1
docker run -it --rm -p 4567:4567 -v app-logs:/var/log/piv_app/ --link rtdb:rtdb rt_cc```

# To Deploy to Production
