# frozen_string_literal: true

# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

35.times do |n|
  Tenant.create!(name: "テナント#{n+1}")
end

puts "Tenants Created"

default_tenant = Tenant.find_by!(name: 'テナント1')
default_proaka = Proaka.find_or_create_by!(name: 'プロアカ1')

30.times do |i|
  user = User.new(
    email:    "test_user#{i}@gmail.com", # sample: test_user1@gmail.com
    name:     "テストuser#{i}",
    password: 'password',
    tenant:   default_tenant,
    proaka:   default_proaka
  )

  user.skip_confirmation! # deviseの確認メールをスキップ
  user.save!
end

names = %i[生澤智史 菅原靖人 養性光明 元永真広 西野鷹也 江草誠]
emails = %i[ikezawa@test.com sugawara@test.com yosei@test.com motonaga@test.com nishino@test.com egusa@test.com]

6.times do |i|
  user = User.new(
    name:     names[i],
    email:    emails[i],
    password: 'password',
    tenant:   default_tenant,
    proaka:   default_proaka
  )

  user.skip_confirmation! # deviseの確認メールをスキップ
  user.save!
end

User.all.each do |u|
  5.times do |i|
    article = u.articles.new(
      title:     "たいとる#{i} author #{u.name}",
      sub_title: "さぶたいとる#{i} author #{u.name}",
      content:   "こんてんつ#{i} author #{u.name}"
    )
    article.save!
  end
end

manager = Manager.new(
  email:    'test_manager@gmail.com',
  name:     'テストmanager1',
  password: 'password'
)

manager.skip_confirmation! # deviseの確認メールをスキップ
manager.save!

admin = Admin.new(
  email:    'test_admin@gmail.com',
  name:     'テストadmin1',
  password: 'password',
  tenant:   default_tenant,
  proaka:   default_proaka
)

admin.skip_confirmation! # deviseの確認メールをスキップ
admin.save!

35.times do
  user = User.order('RAND()').first

  post = Post.new(
    title:       'たいとる',
    body:        'ないよう',
    youtube_url: 'https://www.youtube.com/watch?v=MQG-xF7bv1I&t=4s', # seedで作った動画見られない。手動は見られる。
    user:        user
  )

  post.save!
end

Post.create!(title: 'Rspecについて_2',
  body: 'Rspec勉強会続き',
  youtube_url:'https://www.youtube.com/watch?v=w5KGJ7vJIug',
  created_at: '2023-09-30',
  user_id: '2'
)
Post.create!(title: 'Rspecについて',
  body: 'Rspec勉強会',
  youtube_url: 'https://www.youtube.com/watch?v=Li_pZRUKxV8',
  created_at: '2023-08-30',
  user_id: '5'
)
Post.create!(title: 'Docker入門 〜コンテナファイルの永久化〜',
  body: 'Docker入門',
  youtube_url: 'https://youtu.be/L18szoKQefI',
  created_at: '2023-07-30',
  user_id: '6'
)
Post.create!(title: 'フリーエンジニアになるために必要なこと',
  body: 'rubocopの使い方、DBツールの使い方',
  youtube_url: 'https://youtu.be/Or229iZHCR0',
  created_at: '2023-10-01',
  user_id: '1'
)
Post.create!(title: 'payjpを用いての決済機能について解説',
  body: '質問コーナー',
  youtube_url: 'https://youtu.be/UKKmjAtuwWY',
  created_at: '2022-09-30',
  user_id: '2'
)

puts "Posts Created"

Profile.create!(birthday: '1990-03-30',
  gender: 'male',
  registration_date: '2018-01-01',
  hobby: '野球',
  user_id: '1')
Profile.create!(birthday: '1992-04-10',
  gender: 'female',
  registration_date: '2019-02-02',
  hobby: '読書',
  user_id: '2')
Profile.create!(birthday: '1997-08-18',
  gender: 'female',
  registration_date: '2019-06-06',
  hobby: 'サーフィン',
  user_id: '3')
Profile.create!(birthday: '1960-09-30',
  gender: 'male',
  registration_date: '2019-09-06',
  hobby: '将棋',
  user_id: '4')
Profile.create!(birthday: '2000-12-25',
  gender: 'male',
  registration_date: '2022-05-05',
  hobby: '食べ歩き',
  user_id: '5')

puts "Profile Created"

User.all.each do |u|
  5.times do |i|
    tweet = u.tweets.create!(post: "つぶやきコンテント#{i + 1}")
  end
end

Inquiry.create!(
  user_id: '1',
  subject: 'サポート要求',
  content: 'サポートが必要です',
  created_at: '2023-11-20'
)

Inquiry.create!(
  user_id: '2',
  subject: '料金に関する問い合わせ',
  content: '料金詳細を知りたい',
  created_at: '2023-11-03'
)

Inquiry.create!(
  user_id: '3',
  subject: 'サービス利用方法',
  content: 'どのようにサービスを利用するのか説明してください',
  created_at: '2023-11-02'
)

Inquiry.create!(
  user_id: '4',
  subject: 'アカウントの問題',
  content: 'ログインできない',
  created_at: '2023-11-22'
)

Inquiry.create!(
  user_id: '5',
  subject: '提案',
  content: '新しい機能の提案があります',
  created_at: '2023-11-05'
)

Article.create!(
  [
    {
      title: 'Rails基礎編その1',
      sub_title: 'MVCとは',
      content: 'Railsを使ったアプリケーションを開発する場合、モデル/ビュー/コントローラと呼ばれるものが出てきます。
                モデル/ビュー/コントローラは頭文字を取ってMVCアーキテクチャーと呼ばれるもので、アプリケーションをモデル(データを扱う部分)、
                ビュー(ユーザーに見える結果を作る部分)、コントローラ(ユーザーからの要求を処理し、モデルやビューと連携を行なう)に分割して作りあげるものです。',
      article_type: 'e-learning',
      admin_id: '1'
    },
    {
      title: 'Rails基礎編その2',
      sub_title: 'Modelについて',
      content: 'リクエストが例えば登録済みのデータがみたいといったものや、新しいデータを格納して欲しいといったものの場合、データベースとのやり取りが発生します。
                Railsアプリケーションの場合、使用しているデータベースのテーブル毎にモデルが用意されています。
                利用者からのリクエストで呼び出されたアクションは、モデルを介してデータベースとのやり取りを行い、データを取得したり新しいデータを格納したりします。',
      article_type: 'e-learning',
      admin_id: '1'
    },
    {
      title: 'Rails基礎編その3',
      sub_title: 'Viewについて',
      content: 'モデルを介して取得したデータを受け渡し用の変数にセットしビューを呼び出します。
                ビューは変数を介して渡されたデータを使ってHTML文書を作成しコントローラへ返します。
                ビューはRailsアプリケーションの中に複数用意されています。1つ1つはHTML文書の雛形のようになっており、与えられたデータから文書を作成します。
                通常はアクションに対応するビューが一つ用意されているので自動的にそのビューが呼び出されて利用者へ返す文書を作成するのですが、呼び出すビューを指定することも可能です。',
      article_type: 'e-learning',
      admin_id: '1'
    },
    {
      title: 'Rails基礎編その4',
      sub_title: 'Controllerについて',
      content: 'ビューによって作成されたHTML文書を受け取ったコントローラは、そのデータをリクエストを送信してきた利用者へ返します。',
      article_type: 'e-learning',
      admin_id: '1'
    },
    {
      title: 'メソッド編',
      sub_title: 'paramsとは',
      content: 'paramsとはRailsで送られてきた値を受け取るためのメソッドです。 
                送られてくる情報(リクエストパラメータ)は主に、getのクエリパラメータとPostでformを使って送信されるデータの2つです。',
      article_type: 'e-learning',
      admin_id: '1'
    }
  ]
)
