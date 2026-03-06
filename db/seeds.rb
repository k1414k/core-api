# core-api/db/seeds.rb
Post.find_or_create_by!(slug: "old-project-retrospective") do |post|
  post.title = "昔のプロジェクトをどう捉え直したか"
  post.excerpt = "中途半端に終わった制作物や、昔の粗いコードから何を学んだかを整理した記録。"
  post.content = <<~TEXT
    昔のプロジェクトは、今見るとコード品質に課題がありました。

    ただ、その時はまず形にすることを優先していて、
    今は責務分離や保守性を重視するようになりました。

    この経験から、現在の個人開発では
    Rails API と Next.js の役割を分け、
    後から管理画面や記事機能を足しやすい構成を意識しています。
  TEXT
  post.cover_image_url = "https://images.unsplash.com/photo-1516321318423-f06f85e504b3?auto=format&fit=crop&w=1200&q=80"
  post.status = :published
  post.published_at = Time.current
end

Post.find_or_create_by!(slug: "auction-build-log") do |post|
  post.title = "Auction を作る中で考えた構成"
  post.excerpt = "Rails API / Next.js / AWS を中心に、公開と改善を前提にした構成メモ。"
  post.content = <<~TEXT
    Auction は中古オークションをテーマにした個人開発です。

    フロントと API を分離し、
    将来的な管理画面追加や権限管理も見据えて設計しています。

    見た目だけでなく、
    あとから直しやすい構成をどう作るかを重視しています。
  TEXT
  post.cover_image_url = "https://images.unsplash.com/photo-1520607162513-77705c0f0d4a?auto=format&fit=crop&w=1200&q=80"
  post.status = :published
  post.published_at = 1.day.ago
end