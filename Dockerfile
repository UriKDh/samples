FROM ruby:2.5

# Install OS packages
RUN apt-get update && \
    apt-get install -y \
    git \
    nodejs

# Create application directory
WORKDIR /app

# Add app dependencies
ADD gems.rb ./
ADD gems.locked ./

RUN gem install bundler && bundle install --jobs 20 --retry 5 --without development test

# Set Rails to run in production
ENV RAILS_ENV production
ENV RACK_ENV production

# Copy the application code
ADD . /app

# Create tmp folders
RUN mkdir -p /app/tmp/pids /app/tmp/cache /app/tmp/sockets

# Expose port 3000 to the Docker host, so we can access it
# from the outside.
EXPOSE 3000

# Start puma
CMD bundle exec puma
VOLUME /app/public
