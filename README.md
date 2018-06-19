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

## Viewの作成


