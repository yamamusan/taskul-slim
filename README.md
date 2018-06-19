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

## Step6:タスクモデルの初期作成 
