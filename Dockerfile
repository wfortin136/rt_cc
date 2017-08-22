FROM ruby:2.3.4

RUN apt-get update
RUN apt-get install -y git-core 
#RUN apt-get install -y libpq-dev postgresql-9.4 postgresql-server-dev-9.4
RUN gem install bundler

ADD . /opt/piv_app

EXPOSE 4567

RUN mkdir -p /var/log/piv_app && touch /var/log/piv_app/access.log
WORKDIR /opt/piv_app

RUN bundle install

#ENTRYPOINT ["ruby","rtchallenge.rb"]
CMD ["bundle", "exec", "rackup", "config.ru", "-p", "4567", "-o", "0.0.0.0"]

