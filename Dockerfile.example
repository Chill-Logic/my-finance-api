FROM ruby:3.2.2

ARG _workdir=/my-finance-api

WORKDIR ${_workdir}

COPY Gemfile ${_workdir}/Gemfile
COPY Gemfile.lock ${_workdir}/Gemfile.lock
RUN bundle

COPY . ${_workdir}

EXPOSE 3000
CMD ["bundle", "exec", "puma", "-c", "config/puma.rb"]