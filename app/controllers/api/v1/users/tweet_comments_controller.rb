# app/controllers/api/v1/users/tweet_comments_controller.rb【新規作成】
# ユーザーがつぶやきにコメントを投稿するAPIコントローラー。
# tweet_comments テーブルの recipient_id には投稿先のツイート所有者IDをセットする。
class Api::V1::Users::TweetCommentsController < Api::V1::BaseController
  before_action :authenticate_user!
  before_action :set_tweet

  # POST /api/v1/tweets/:tweet_id/comments
  def create
    comment = @current_user.tweet_comments.build(
      content:      params[:content],
      tweet_id:     @tweet.id,
      # recipient_id は通知先のユーザー（ツイート投稿者）のID
      recipient_id: @tweet.user_id
    )
    if comment.save
      render json: { comment: comment_json(comment) }, status: :created
    else
      render json: { errors: comment.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def set_tweet
    @tweet = Tweet.includes(:user).find_by(id: params[:tweet_id])
    render_not_found('つぶやき') unless @tweet
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
