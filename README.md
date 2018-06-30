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

上記はcoffeescriptにメッセージがべた書きなのでi18n対応をしたい

* Gemfileに追加して、`bundle install`

```
gem 'i18n-js'
```
* application.jsに以下を追加

```
//= require i18n
//= require i18n/translations
```
* application.html.slimに以下を追加

```
    javascript:
      I18n.defaultLocale = "#{I18n.default_locale}";
      I18n.locale = "#{I18n.locale}";
      I18n.fallbacks = true;
```

* `buner i18n:js:export`を実施して、ja.ymlとかをtranslations.jsに書き出す(初回だけやっておけばOKっぽい)
* あとは、`confirm (I18n.t('view.confirm.destroy'))`のようにやってあげれば同じように使える
* なお、このやり方はcoffe-scriptじゃなくても使える模様

## リストのアクションをアイコンにしよう

* GoogleのMaterialDesignから適切なアイコンをダウンロード
* imagesの下に置いて、slimからは以下のように指定すればOK

```
td.px-0.d-flex
  .mx-1 = link_to image_tag('detail.png'), task
  .mx-1 = link_to image_tag('edit.png'), edit_task_path(task)
  .mx-1 = link_to image_tag('delete.png'), task, data: { confirm: t('view.confirm.destroy') }, method: :delete
```

## Railsのタイムゾーンを日本（東京）に設定&フォーマット修正

* タイムゾーンの設定は`application.rb`に以下を設定すれば良い

```
    config.time_zone = 'Tokyo'   
```
* 時間フォーマットの設定は`config/initilizer/time_formats.rb`に以下のように記載

```
Time::DATE_FORMATS[:default] = '%Y/%m/%d %H:%M'
Time::DATE_FORMATS[:datetime] = '%Y/%m/%d %H:%M'
Time::DATE_FORMATS[:date] = '%Y/%m/%d'
Time::DATE_FORMATS[:time] = '%H:%M:%S'
Date::DATE_FORMATS[:default] = '%Y/%m/%d'
```

## 一覧の結果をカード表示

* だいたい以下のような感じで、カード化に成功
* ポイントは、画像を良い感じに表示するための`taskul-card-img`
* あと、card-deckは複数行だと変になるので、行内で高さを固定するためにh-100を指定している点。

```
  .row
    - @tasks.each_with_index do |task, index|
      .col-6.col-md-3.mb-4
        .card.h-100
          .card-header.taskul-color-card.text-white.text-truncate = task.title
          = link_to image_tag("card#{(1..4).to_a.sample}.jpg", class: 'card-img-top taskul-card-img'), task
          .card-body
            p.card-text = task.description
            span.badge.badge-success.mr-2 = task.priority
            span.badge.badge-info.mr-2 = task.status
          .card-footer.d-flex.justify-content-center
            .mx-3 = link_to image_tag('detail.png'), task
            .mx-3 = link_to image_tag('edit.png'), edit_task_path(task)
            .mx-3 = link_to image_tag('delete.png'), task, data: { confirm: t('view.confirm.destroy') }, method: :delete
```

## ページングの導入

### kaminariの導入

* Gemfileに`gem 'kaminari'`を追加して、`bundle install`

### テスト用に多めのデータを投入しておく

* `seeds.rb`を作成.Fakerを使って、ランダムデータを積んでみる

```
100.times do |_n|
  title = Faker::Lorem.sentence
  description = Faker::Lorem.paragraph
  status = [0, 1, 2].sample
  priority = [-1, 0, 1].sample
  Task.create!(title: title, description: description, status: status,
               priority: priority)
end
```

* `buner db:seed`を実行し、１０件分のランダムデータを積む

### ひとまず最低限の実装でページングを実現

* コントローラに以下の処理を追加

```
  def index
    @tasks = Task.page(params[:page])
    # 個別にページ件数を指定したい場合は以下
    # @tasks = Task.page(params[:page]).per(25)
  end
```
* view(index.html.slim)に以下１行を追加
* なお、一覧の上下に出したければ、２個書けばOK

```
  = paginate @tasks
```

### kaminariの全体設定を定義する

* `buner g kaminari:config`でconfigファイルを生成
* 以下のように1ページあたりの件数を20件に設定

```
Kaminari.configure do |config|
  config.default_per_page = 20
  # config.max_per_page = nil
  # config.window = 4
  # config.outer_window = 0
  # config.left = 0
  # config.right = 0
  # config.page_method_name = :page
  # config.param_name = :page
  # config.params_on_first_page = false
end
```

### 見た目をおしゃれにする(bootstrap4ベースで)

* `buner g kaminari:views bootstrap4`でbootstrap4ベースでのおしゃれな感じにしてくれる

### XX件中XX件みたいな表示をする

* `= page_entries_info @tasks`を入れることで上記のような情報を出してくれる

### ページング部品の日本語化

* XX件中XX件とあわせて、ja.ymlに以下を追加する

```
ja:
  views:
    pagination:
      first: "&laquo; 最初"
      last: "最後 &raquo;"
      previous: "&lsaquo; 前"
      next: "次 &rsaquo;"
      truncate: "&hellip;"
  helpers:
    page_entries_info:
      one_page:
        zero: "<b>該当データがありません。</b>"
        one: "<b>1件中 1-1 件を表示</b>"
        display_entries: '1-%{count}件を表示中 / 合計%{count}件'
      more_pages:
```

## コメント機能の追加(has_many)

TODO!!いまここ!!!

## 検索機能の追加(モーダルで実装)




