FROM ruby:2.3.4

RUN apt-get update
RUN apt-get install -y git-core 
#RUN apt-get install -y libpq-dev postgresql-9.4 postgresql-server-dev-9.4
RUN gem install bundler

# Setup logstash
ADD logstash/logstash.conf /usr/share/logstash/pipeline/logstash.conf
VOLUME /usr/share/logstash/pipeline

# Setup App
EXPOSE 4567
ADD . /opt/piv_app
RUN mkdir -p /var/log/piv_app
WORKDIR /opt/piv_app
RUN bundle install

CMD ["bundle", "exec", "rackup", "config.ru", "-p", "4567", "-o", "0.0.0.0"]
