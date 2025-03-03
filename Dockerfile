FROM ruby:3.3.6

LABEL Version="1.0"
LABEL Name="Examinis Student"
LABEL Maintainer="Examinis"
LABEL Description="Docker image for Rails development using a PostgreSQL database"

# Install dependencies
RUN apt-get update -qq && apt-get install -y build-essential libpq-dev nodejs yarn && apt-get clean

# Set the app's workdir
WORKDIR /usr/src/app

# Copy the dependecies' files
COPY Gemfile /usr/src/app/Gemfile
COPY Gemfile.lock /usr/src/app/Gemfile.lock

# Install gems
RUN bundle install

# Copy the app's source code
COPY . /usr/src/app

EXPOSE 3000

# Command for executing the application
CMD ["rails", "server", "-b", "0.0.0.0"]
