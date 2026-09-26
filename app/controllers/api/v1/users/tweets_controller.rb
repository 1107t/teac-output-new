# app/controllers/api/v1/users/tweets_controller.rb【修正】
# ユーザー向けつぶやきAPIコントローラー。CRUD + 画像添付に対応。
# tweet_json が userName・imageUrls・likesCount・likedByCurrentUser を返すよう拡張した。
class Api::V1::Users::TweetsController < Api::V1::BaseController
  before_action :authenticate_user!
  before_action :set_tweet, only: [:show, :update, :destroy]

  # GET /api/v1/tweets
  # クエリパラメータ user_id が渡された場合は該当ユーザーの投稿のみ返す
  def index
    tweets = Tweet
      .includes(:user, :likes, tweet_comments: :user)
      .order(created_at: :desc)
    tweets = tweets.where(user_id: params[:user_id]) if params[:user_id].present?
    render json: { tweets: tweets.map { |tweet| tweet_json(tweet) } }
  end

  # GET /api/v1/tweets/:id
  def show
    render json: { tweet: tweet_json(@tweet) }
  end

  # POST /api/v1/tweets
  # multipart/form-data で content（文字列）と images[]（ファイル）を受け取る
  def create
    tweet = @current_user.tweets.build(post: tweet_content_param)
    tweet.images.attach(params[:images]) if params[:images].present?
    if tweet.save
      render json: { tweet: tweet_json(tweet) }, status: :created
    else
      render json: { errors: tweet.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PATCH /api/v1/tweets/:id
  def update
    unless @tweet.user_id == @current_user.id
      return render json: { error: '権限がありません' }, status: :forbidden
    end

    if @tweet.update(post: tweet_content_param)
      render json: { tweet: tweet_json(@tweet) }
    else
      render json: { errors: @tweet.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/tweets/:id
  def destroy
    unless @tweet.user_id == @current_user.id
      return render json: { error: '権限がありません' }, status: :forbidden
    end

    @tweet.destroy
    render json: { message: '削除しました' }
  end

  private

  def set_tweet
    @tweet = Tweet.find_by(id: params[:id])
    render_not_found('つぶやき') unless @tweet
  end

  # フロントエンドは "content" キーで送ってくるが DBカラム名は "post" のため手動でマッピングする
  def tweet_content_param
    params[:content].presence || params.dig(:tweet, :content)
  end

  # ツイートをJSON形式に変換する。
  # - content: DBの post カラムをフロントエンドが期待する content キーにマッピング
  # - imageUrls: Active Storage の添付画像を URL 配列で返す
  # - likedByCurrentUser: 現在のユーザーがいいね済みかどうか
  def tweet_json(tweet)
    {
      id:                 tweet.id.to_s,
      content:            tweet.post,
      userId:             tweet.user_id.to_s,
      userName:           tweet.user.name,
      imageUrls:          tweet_image_urls(tweet),
      likesCount:         tweet.likes.size,
      likedByCurrentUser: tweet.likes.any? { |like| like.user_id == @current_user.id },
      comments:           tweet.tweet_comments.map { |comment| comment_json(comment) },
      createdAt:          tweet.created_at.iso8601,
      updatedAt:          tweet.updated_at.iso8601
    }
  end

  # Active Storage の添付画像を絶対URLの配列で返す
  def tweet_image_urls(tweet)
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
