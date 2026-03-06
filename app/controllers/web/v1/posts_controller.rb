class Web::V1::PostsController < ApplicationController
  def index
    posts = Post.published_ordered

    render json: {
      posts: posts.map do |post|
        {
          id: post.id,
          title: post.title,
          slug: post.slug,
          excerpt: post.excerpt,
          cover_image_url: post.cover_image_url,
          published_at: post.published_at
        }
      end
    }
  end

  def show
    post = Post.published.find_by!(slug: params[:slug])

    render json: {
      post: {
        id: post.id,
        title: post.title,
        slug: post.slug,
        excerpt: post.excerpt,
        content: post.content,
        cover_image_url: post.cover_image_url,
        published_at: post.published_at
      }
    }
  end
end