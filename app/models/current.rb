# frozen_string_literal: true

# リクエスト単位で「今どのテナントの文脈か」を保持する。
# BaseController#authenticate! で current_tenant がセットされ、
# レスポンス送出後は Rails (ActiveSupport::Executor) が自動でリセットする。
class Current < ActiveSupport::CurrentAttributes
  attribute :tenant
end
