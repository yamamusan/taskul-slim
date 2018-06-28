# 初期構築

##  プロジェクトの作成

```
bundle init
# Gemfileのrailsコメントアウト解除

bundle install --path vendor/bundle
buner new . -B --webpack=vue --skip-test
buner webpacker:install
```

## Slimの導入

* Gemfileに以下を追記し、`bundle install`

```
gem 'slim-rails'
```

* ジェネレータのテンプレートエンジンをslimに変更する(application.rb)

```
config.generators.template_engine = :slim
```

## hello-slim

* 以下で、`http://localhost:3000/products`でCRUD画面が使えるようになる
```
buner g scaffold Product name:string description:text price:integer discontinued:boolean
buner db:migrate
buner s
```

* 以下で、元に戻しておく

```
buner destroy scaffold Product
```

## 必要なGem等のセットアップ

```
group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem "faker"
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
  gem "rspec-rails"
  gem "factory_bot_rails"
  gem "guard-rspec"
  gem 'turnip'
end

group :development do
  # Access an interactive console on exception pages or by calling 'console' anywhere in the code.
  gem 'web-console', '>= 3.3.0'
  gem 'listen', '>= 3.0.5', '< 3.2'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
  gem 'foreman'
  gem 'meta_request'
  gem 'pry-byebug'
  gem 'ruby-debug-ide', '0.6.0'
  gem 'debase'
end

group :test do
  gem "capybara"
  gem "selenium-webdriver"
  gem 'chromedriver-helper'
  gem "database_cleaner"
  gem "launchy"
  gem "shoulda-matchers"
end
```

```
bundle install
buner g rspec:install
mkdir -p spec/features spec/steps
```
* また、準備として、`.rspec`に以下の記載を追加する

```
--format documentation
--require turnip/rspec
```
* また、`spec_helper.rb`に以下の記載を追加する

```
Dir.glob("spec/**/*steps.rb") { |f| load f, true }

# Capybara自体の設定、ここではどのドライバーを使うかを設定しています
Capybara.configure do |capybara_config|
  capybara_config.default_driver = :selenium_chrome
  capybara_config.default_max_wait_time = 10 # 一つのテストに10秒以上かかったらタイムアウトするように設定しています
end
# Capybaraに設定したドライバーの設定をします
Capybara.register_driver :selenium_chrome do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  options.add_argument('headless') # ヘッドレスモードをonにするオプション
  options.add_argument('--disable-gpu') # 暫定的に必要なフラグとのこと
  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
end

Capybara.javascript_driver = :selenium_chrome
```

# 開発開始

## タスクモデルの作成 

* 以下のコマンドでモデルを作成する

```
buner g model Task title:string description:text priority:integer status:integer due_date:date
```

* migrationファイルを以下のように修正し、`buner db:migrate:reset`
```
class CreateTasks < ActiveRecord::Migration[5.2]
  def change
    create_table :tasks do |t|
      t.string :title, null: false
      t.text :description
      t.integer :priority
      t.integer :status, default: 0, null: false
      t.date :due_date

      t.timestamps
    end
  end
end
```

* タスクモデルを以下のように修正(バリデーション追加)

```
class Task < ApplicationRecord
  attr_accessor :statuses, :priorities

  enum priority: { normal: 0, low: -1, high: 1 }, _prefix: true
  enum status: { todo: 0, doing: 1, done: 2 }, _prefix: true

  validates :title, presence: true, length: { maximum: 256 }
  validates :status, presence: true
  validate :not_before_today

  scope :title_like, ->(title) { where('title like ?', "%#{title}%") if title.present? }
  scope :description_like, ->(description) { where('description like ?', "%#{description}%") if description.present? }
  scope :status_in, ->(statuses) { where(status: statuses) if statuses.present?}
  scope :priority_in, ->(priorities) { where(priority: priorities) if priorities.present?}

  def search
    Task.title_like(title).description_like(description).status_in(statuses).priority_in(priorities)
  end

  def not_before_today
    errors.add(:due_date, :not_before_today) if due_date.present? && due_date < Date.today
  end
end
```

* タスクモデルに対する、ユニットテストを追加する
  * まずは、factorybotベースのテストデータファイルを準備

```
FactoryBot.define do
  factory :base, class: 'Task' do
    title 'This is Title'
    description 'Description'
    status :doing
    priority :normal

    factory :data1, class: 'Task' do
      title 'Jenkins'
      description 'Jenkins is cool'
    end
    factory :data2, class: 'Task' do
      title 'Jenkins And GitLab'
      description 'Teher are cool'
    end
   (略)
  end
end
```
  * 続いて、task_spec.rbを整備

```
  describe 'バリデーション' do
    let(:base) { build(:base) } # メモリ上に展開

    describe '全項目' do
      context '全項目入力' do
        example 'エラーにならないこと' do
          expect(base).to be_valid
        end
      end
      context '必須項目のみ入力' do
        example 'エラーにならないこと' do
          expect(Task.new(title: 'a', status: :doing)).to be_valid
        end
      end
    end
   (略)
```
  * `bundle exec rspec spec/models/`でテストが通過することを確認する

## 画面遷移について考える

* 画面遷移図は`plantuml`で書いてみる
* VSCodeでplantuml環境を構築する
  * `brew cask install java`でJavaをインストール
  * VSCodeの拡張機能で`PlantUML`をインストール
  * `brew install graphviz`でgraphivizをインストール
  * 一応動いたが、遅いし、画面遷移図というより状態遷移図なのでやーめた
* 代わりに`guiflow`というUI FLowsをテキストで描けるツールが良さげ。(マークダウンには入れられないが・・)

## Controllerの作成 

* `buner g scaffold_controller task --no-controller-specs --no-view-specs --no-helper-specs --no-routing-specs --no-request-specs`で、コントローラの雛形を作成
* 毎回オプションを指定するのは面倒なので、applicaiton.rbを以下のようにする

```
config.generators do |g|
  g.system_tests = nil
  g.template_engine = :slim
  g.view_specs false
  g.helper_specs false
  g.routing_specs false
  g.controller_specs false
  g.request_specs false
end
```

* これで以降は、`buner g scaffold_controller task`でいける

## Routingの作成

```
Rails.application.routes.draw do
  resources :tasks, except: %i[destroy] do
    delete :index, on: :collection, action: :delete
  end
end
```

## Controllerの修正

* 以下のように、permitを追加.ついでにsearch_paramsも追加

```
def task_params
  params.fetch(:task, {}).permit(:title, :description, :status, :priority, :due_date)
end
def search_params
  params.permit(:title, :due_date, :description, statuses: [], priorities: [])
end
```

## Viewの作成

* 登録、更新画面に項目を追加(_form.html.slim)

```
  .field
    = f.label :title
    = f.text_field :title
  .field
    = f.label :description
    = f.text_area :description
  .field
    = f.label :priority
    = f.select :priority, Task.priorities.keys.to_a
  .field
    = f.label :status
    = f.select :status, Task.statuses.keys.to_a
  .field
    = f.label :due_date
    = f.date_select :due_date

  / コメント
  .actions = f.submit
```

* 詳細画面に項目を追加(show.html.slim)

```
= form_for @task do |f|
  .item
    = f.label :title, class: "inline"
    = @task.title
  .item
    = f.label :description, class: "inline"
    = @task.description
  .item
    = f.label :priority, class: "inline"
    = @task.priority
  .item
    = f.label :status, class: "inline"
    = @task.status
  .item
    = f.label :due_date, class: "inline"
    = @task.due_date
```

* 一覧画面に項目を追加(index.html.slim)

```
table
  thead
    tr
      th Title
      th Description
      th Priority
      th Status
      th Due date
      th
      th
      th

  tbody
    - @tasks.each do |task|
      tr
        td = task.title
        td = task.description
        td = task.priority
        td = task.status
        td = task.due_date
        td = link_to 'Show', task
        td = link_to 'Edit', edit_task_path(task)
        td = link_to 'Destroy', task, data: { confirm: 'Are you sure?' }, method: :delete

br

= link_to 'New Task', new_task_path
```

## bootstarpを導入する

* gem をインストール(以下をGemfileに記載して`bundle install`)

```
gem 'bootstrap', '~> 4.1.1'
gem 'jquery-rails'
```

* 以下で、application.cssをapplication.scssにリネームする

```
mv app/assets/stylesheets/application.css app/assets/stylesheets/application.scss
```

* app/assets/stylesheets/application.scssでbootstrapをimportさせる(中身を置き換える)

```
// Custom bootstrap variables must be set or imported *before* bootstrap.
@import "bootstrap";mv app/assets/stylesheets/application.css
```

* Bootstrapと依存関係をapplication.jsに追記する

```
//= require jquery3
//= require popper
//= require bootstrap-sprockets
```

## デザインをかっこよくする

### スタイルシートの管理方法を考える

* まず仕組みとして、application.html.erbで以下のように指定しているので、applcation.scssがロードされ、それをベースにcssのリンクタグが生成される　

```
<%= stylesheet_link_tag    'application', media: 'all', 'data-turbolinks-track': 'reload' %>
```

* なので、application.scssには以下の用に定義することとする
* これは、bootstrapはまず最初に読み込んで、そのあとに、共通cssを、そのあとは個別のやつを読み込む感じ
* あれ？この場合、taskの場合、task.scssだけ読み込むとかはできんのかな？まあいいか.

```
@import "bootstrap";
@import "common.scss";
@import "partial/*";
```

### 共通のヘッダやフッタを整備するには

* こちらもapplication.html.erbで定義する。
* まず、application.html.erbをslim形式に変換して、nvabarを設置する

### 画像を参照するには

* assets/images以下に画像をおいたら、以下のように指定すればOK

```
= image_tag('user.png') 
```

### 中身の画面もおしゃれにする

* 一覧、登録、編集画面を整備する(ここはコミット参照)
* ⭐️今ココ！登録と編集画面はまだ。後ででいいかな。。。

## 多言語対応をする

* まず、デフォルトの言語設定を日本語にするため、`application.rb`に以下の設定を追加する

```
config.i18n.default_locale = :ja
```
* `config/locales/ja.yml`を作成する
* `https://github.com/svenfuchs/rails-i18n/blob/master/rails/locale/ja.yml`の内容をローカルにコピーする
* これで、 バリデーションメッセージは`バリデーションに失敗しました: Titleを入力してください`のように日本語化される
* :Titleの部分も日本語化したい。`config/locales/ja.yml`に以下を追記する
```
ja:
  activerecord:
    models:
      task: タスク
    attributes:
      task:
        title: タイトル
        description: 説明
```
* これで、`バリデーションに失敗しました: タイトルを入力してください`のように表示されるようになる
* 今回、以下のような独自メッセージも追加している。

```
def not_before_today
  errors.add(:due_date, 'Please set today or after today') if due_date.present? && due_date < Date.today
end
```
* これを多言語対応してみる。まず、`task.rb`のバリデーションを以下のように変更

```
  errors.add(:due_date, :not_before_today) if due_date.present? && due_date < Date.today
```
* ja.ymlに以下を追加

```
  errors:
    format: "%{attribute}%{message}"
    messages:
      (略)
      not_before_today: "には本日以降の日付を指定してください"
```
* これで、`バリデーションに失敗しました: 期限は本日以降の日付を指定してください`のように表示されるようになる
* 続いて、ボタン名などフロントオンリーのものも多言語化
  * まずは、ja,ymlに以下を追加

```
  button:
    new: 新規作成
    show: 詳細
    edit: 編集
    destroy: 削除
    back: 戻る
```
  * view側では以下のような感じで指定する　

```
td = link_to t('button.show'), task
```

* TODO:バリデーションエラー時に`error prohibited this task from being saved:`と出たまま。
  * ここはべたで書いてるから。まあいっか。余裕があればscaffoldのテンプレートいじってみる

## ルートパスの変更

* `routes.rb`に以下のように書くだけ

```
  root to: 'tasks#index'
```

## coffee script使いたくないけど使う

* まず、全選択解除チェックボックスの実装(tasks.coffee)

```
jQuery ->
  $("#checkbox-header").click ->
    $('.checkbox-list').prop('checked', $('#checkbox-header').prop('checked'))
```
* 一括削除ボタン押下時の処理(tasks.coffee)
```
jQuery ->
  ...
  $("#delete-btn").click ->
    check_count = $('.checkbox-list:checked').length;
    if check_count == 0
      alert 'no delete target checked'
      return false // submitを中断する
    else
      confirm 'delete tasks?'
```

## coffescriptのi18n対応

* TODO

## FeatureSpecの更新


## 登録と更新を子画面化(vuejsを使用)


