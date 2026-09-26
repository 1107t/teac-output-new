# app/controllers/api/v1/admin/tweets_controller.rb【新規作成】
# 管理者がユーザーのつぶやきを閲覧するAPIコントローラー（読み取り専用）。
# 管理者は user_id を持たないため、いいね・コメント投稿は提供しない。
class Api::V1::Admin::TweetsController < Api::V1::BaseController
  before_action :authenticate_admin!
  before_action :set_target_user

  # GET /api/v1/admin/users/:user_id/tweets
  # 指定ユーザーのつぶやきを新着順で返す
  def index
    tweets = @target_user.tweets
      .includes(:user, :likes, tweet_comments: :user)
      .order(created_at: :desc)
    render json: { tweets: tweets.map { |tweet| admin_tweet_json(tweet) } }
  end

  private

  def set_target_user
    @target_user = User.find_by(id: params[:user_id])
    render_not_found('ユーザー') unless @target_user
  end

  # 管理者向けツイートJSON。likedByCurrentUser は管理者には不要なため含めない。
  def admin_tweet_json(tweet)
    {
      id:         tweet.id.to_s,
      content:    tweet.post,
      userId:     tweet.user_id.to_s,
      userName:   tweet.user.name,
      imageUrls:  admin_tweet_image_urls(tweet),
      likesCount: tweet.likes.size,
      comments:   tweet.tweet_comments.map { |comment| comment_json(comment) },
      createdAt:  tweet.created_at.iso8601,
      updatedAt:  tweet.updated_at.iso8601
    }
  end

  def admin_tweet_image_urls(tweet)
    return [] unless tweet.images.attached?
    tweet.images.map do |image|
      Rails.application.routes.url_helpers.rails_blob_url(image, host: request.base_url)
    end
  end

  def comment_json(comment)
    {
      id:        comment.id.to_s,
      content:   comment.content,
      userId:    comment.user_id.to_s,
      userName:  comment.user&.name,
      createdAt: comment.created_at.iso8601
    }
  end
end
