class Admin < ApplicationRecord
  # Include default devise modules. Others available are:
  # :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
    :recoverable, :rememberable, :validatable,
    :confirmable

  belongs_to :tenant
  belongs_to :proaka, class_name: 'Proaka', foreign_key: 'プロアカ_id'

  # リクエスト中に current_tenant が判明していれば、そのテナントの行だけを見せる。
  # 未設定（コンソール/マイグレーション/managerとしての操作等）の場合は絞り込まない。
  scope :in_current_tenant, -> { Current.tenant ? where(tenant: Current.tenant) : all }
  default_scope { in_current_tenant }

  has_many :articles, dependent: :destroy
  has_many :posts, dependent: :destroy
  has_one :charge_plan, dependent: :destroy
  
  # 管理者の学習進捗を保持する関連付け
  has_many :learning_status, class_name: "Learning", foreign_key: "admin_id", dependent: :destroy
  
  enum gender: { male: 0, female: 1, other: 2 }

  def completed?(article)
    learning_status.exists?(learned_article_id: article.id, completed: true)
  end

  def self.sort_filter(order, filter)
    artcl_min = filter[:articles_min].blank? ? 0 : filter[:articles_min]
    artcl_max = filter[:articles_max].blank? ? Article.count : filter[:articles_max]
    posts_min = filter[:posts_min].blank? ? 0 : filter[:posts_min]
    posts_max = filter[:posts_max].blank? ? Post.count : filter[:posts_max]
    admins = where(['name like ? and email like ?', "%#{filter[:name]}%", "%#{filter[:email]}%"])
      .left_joins(:articles).left_joins(:posts).group('admins.id')
      .having('count(articles.id) between ? and ?', artcl_min, artcl_max)
      .having('count(posts.id) between ? and ?', posts_min, posts_max)
    if order[0] == :articles || order[0] == :posts
      admins.order("COUNT(#{order[0]}.id) #{order[1]}")
    else
      admins.order(order[0] => order[1])
    end
  end

  def have_charge_plan?(admin)
    ChargePlan.where(admin_id: admin.id).exists?
  end
end
