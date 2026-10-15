class Post < ApplicationRecord
  before_validation :set_tenant_from_owner, on: :create

  belongs_to :admin, optional: true
  belongs_to :user, optional: true
  belongs_to :tenant

  # リクエスト中に current_tenant が判明していれば、そのテナントの行だけを見せる。
  # 未設定（コンソール/マイグレーション等）の場合は絞り込まない。
  scope :in_current_tenant, -> { Current.tenant ? where(tenant: Current.tenant) : all }
  default_scope { in_current_tenant }

  has_many :likes
  has_many :post_comments, dependent: :destroy

  validates :user_id, presence: true, if: -> { admin_id.blank? }
  validates :admin_id, presence: true, if: -> { user_id.blank? }
  validates :title, presence: true, length: { maximum: 30 }
  validates :body, presence: true, length: { maximum: 240 }
  validates :youtube_url, presence: true

  def self.filtered_and_ordered_posts(params, page, per_page)
    params[:order] ||= 'DESC'
    filter = {
      author: params[:author],
      body:   params[:body],
      title:  params[:title],
      start:  params[:start],
      finish: params[:finish],
      order:  params[:order]
    }
    posts = self.includes(:user, :admin)

    if params.present?
      posts = posts.apply_filters(params)
    end

    posts.order(created_at: 'DESC').page(page).per(per_page)
  end

  def self.apply_filters(filter)
    start = Time.zone.parse(filter[:start].to_s.presence || '2022-01-01').beginning_of_day
    finish = Time.zone.parse(filter[:finish].to_s.presence || Date.current.to_s).end_of_day

    left_joins(:user, :admin)
      .where(['title LIKE ? AND body LIKE ?',
              "%#{filter[:title]}%", "%#{filter[:body]}%"])
      .where('posts.created_at BETWEEN ? AND ?', start, finish)
      .where('users.name LIKE :author OR admins.name LIKE :author', author: "%#{filter[:author]}%")
      .order("posts.created_at #{filter[:order]}")
      .presence || Post.none
  end

  private

    def set_tenant_from_owner
      self.tenant ||= user&.tenant || admin&.tenant
    end
end
