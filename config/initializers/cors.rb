# CORS設定：フロントエンド（Next.js）からのリクエストを許可する
# credentials: true にすることで、Cookieを使った認証（devise_token_auth）が動く

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    # FRONTEND_ORIGINS でカンマ区切りの複数フロントエンドを許可できるようにする。
    # 例）https://auction.jongin.blog,https://admin.jongin.blog
    raw_origins =
      ENV["FRONTEND_ORIGINS"].presence ||
      ENV.fetch("FRONTEND_URL", "http://localhost:3001")

    origins raw_origins.split(",").map(&:strip)

    resource "*",
      headers: :any,
      # devise_token_auth の認証ヘッダをフロントに公開する（必須）
      expose: ["access-token", "expiry", "token-type", "uid", "client"],
      methods: [:get, :post, :put, :patch, :delete, :options, :head],
      credentials: true   # Cookieを送受信するために必須
  end
end
