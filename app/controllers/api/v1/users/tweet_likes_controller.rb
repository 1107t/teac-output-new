# app/controllers/api/v1/users/tweet_likes_controller.rb【新規作成】
# ユーザーがつぶやきにいいねする/解除するAPIコントローラー。
# likes テーブルの tweet_id カラムを使用する。二重いいねは Like モデルのバリデーションで防ぐ。
class Api::V1::Users::TweetLikesController < Api::V1::BaseController
  before_action :authenticate_user!
  before_action :set_tweet

  # POST /api/v1/tweets/:tweet_id/like
  # いいね済みでない場合のみ Like レコードを作成する
  def create
    like = @current_user.likes.find_or_initialize_by(tweet_id: @tweet.id)
    if like.new_record?
      like.save
      render json: { liked: true, likesCount: @tweet.likes.count }, status: :created
    else
      render json: { error: 'すでにいいね済みです' }, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/tweets/:tweet_id/like
  # いいねを解除する
  def destroy
    like = @current_user.likes.find_by(tweet_id: @tweet.id)
    return render_not_found('いいね') unless like

    like.destroy
    render json: { liked: false, likesCount: @tweet.likes.count }
  end

  private

  def set_tweet
    @tweet = Tweet.find_by(id: params[:tweet_id])
    render_not_found('つぶやき') unless @tweet
  end
end
