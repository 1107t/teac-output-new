FROM ruby:3.0.3

RUN apt-get update -y && \
    apt-get install default-mysql-client chromium chromium-driver nodejs npm vim graphviz -y && \
    npm uninstall yarn -g && \
    npm install yarn -g -y

# ルート直下にwebappという名前で作業ディレクトリを作成（コンテナ内のアプリケーションディレクトリ）
RUN mkdir /webapp
WORKDIR /webapp

# ホストのGemfileとGemfile.lockをコンテナにコピー
ADD Gemfile /webapp/Gemfile
ADD Gemfile.lock /webapp/Gemfile.lock

# bundle installの実行
RUN bundle install -j4

# ホストのアプリケーションディレクトリ内をすべてコンテナにコピー
ADD . /webapp

EXPOSE 3000

CMD bash -c "rm -f tmp/pids/server.pid && bundle exec puma -C config/puma.rb"

