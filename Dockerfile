# ===================================================
# Rails API 用 Dockerfile（ローカル開発・本番共通）
# ベースイメージ：Ruby 3.2.4 on Debian Slim
# ===================================================

# --- ステージ1: ベース ---
# Ruby公式イメージを使う。slimは不要なパッケージが入っていないので軽量
FROM ruby:3.2.4-slim AS base

# 必要な環境変数をセット
ENV RAILS_ENV=production \
    BUNDLE_WITHOUT="development:test" \
    BUNDLE_DEPLOYMENT=1 \
    LANG=C.UTF-8 \
    PATH="/usr/local/bundle/bin:${PATH}"

# システムパッケージをインストール
# - build-essential: gemのネイティブ拡張コンパイルに必要
# - libpq-dev:       PostgreSQL接続に必要（pggemが依存する）
# - curl:            ヘルスチェックなどで使用
RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
      build-essential \
      libpq-dev \
      curl && \
    rm -rf /var/lib/apt/lists/*   # キャッシュ削除してイメージを軽量化

WORKDIR /app   # コンテナ内の作業ディレクトリを /app に設定

# --- ステージ2: gem インストール ---
FROM base AS bundle_install

# まず Gemfile だけをコピーする
# →ここが変わらなければ bundle install はキャッシュされる（ビルドが速くなる）
COPY Gemfile Gemfile.lock ./

# gemをインストール（development/testグループは除外）
RUN bundle install --jobs=$(nproc) --retry 3

# --- ステージ3: 最終イメージ ---
FROM base AS final

WORKDIR /app

# インストール済みのgemをコピー
COPY --from=bundle_install /usr/local/bundle /usr/local/bundle

# アプリケーションコード全体をコピー
COPY . .

# entrypoint.sh に実行権限を付与
RUN chmod +x /app/entrypoint.sh

# Railsが使うポート
EXPOSE 3000

# コンテナ起動時に entrypoint.sh を実行し、その後 rails server を起動
ENTRYPOINT ["/app/entrypoint.sh"]
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0", "-p", "3000"]
