FROM ruby:3.2.4-slim

ENV RAILS_ENV=production \
    BUNDLE_WITHOUT="development:test" \
    LANG=C.UTF-8 \
    PATH="/usr/local/bundle/bin:${PATH}"

RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
      build-essential \
      libpq-dev \
      curl && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Gem を先に入れる
COPY Gemfile Gemfile.lock ./
RUN bundle install --jobs=$(nproc) --retry 3

# アプリコードをコピー
COPY . .

RUN chmod +x /app/entrypoint.sh

EXPOSE 3000

ENTRYPOINT ["/app/entrypoint.sh"]
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0", "-p", "3000"]